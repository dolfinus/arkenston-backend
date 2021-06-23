defmodule Arkenston.Repo.Migration do
  use Ecto.Migration
  import Inflex

  @id_name Application.get_env(:arkenston, Arkenston.Repo)[:primary_key][:name]
  @id_type Application.get_env(:arkenston, Arkenston.Repo)[:primary_key][:type]

  @created_by String.to_atom("created_by_#{@id_name}")
  @updated_by String.to_atom("updated_by_#{@id_name}")
  @first_revision String.to_atom("first_revision_#{@id_name}")
  @latest_revision String.to_atom("latest_revision_#{@id_name}")

  @users_data_table "users_data"

  def get_audit_data(view_name) do
    data_table = "#{view_name}_data" |> String.to_atom()
    audit_table = "#{view_name}_audit" |> String.to_atom()
    entity_type = singularize(view_name)
    orig_primary_key = "#{entity_type}_#{@id_name}" |> String.to_atom()

    {data_table, audit_table, entity_type, orig_primary_key}
  end

  def get_columns(columns_list) do
    columns = columns_list |> Enum.map(fn column -> "data.#{column}" end) |> Enum.join(",")
    columns_quoted = columns_list |> Enum.map(fn column -> "'#{column}'" end) |> Enum.join(",")

    {columns, columns_quoted}
  end

  def fetch_columns(view_name) do
    {data_table, _, _, _} = get_audit_data(view_name)

    columns_list =
      repo().query!("
      SELECT
          column_name
      FROM
          information_schema.columns
      WHERE
          table_name = '#{data_table}'
    ")
      |> Map.get(:rows)
      |> Enum.map(fn item ->
        case item do
          [it] -> it
          _ -> item
        end
      end)

    columns_list =
      columns_list
      |> Enum.map(&String.to_atom/1)
      |> Enum.filter(fn item ->
        item not in [@id_name, @first_revision, @latest_revision, @created_by, :created_at]
      end)

    get_columns(columns_list)
  end

  def create_audit_view(view_name) do
    {columns, columns_quoted} = fetch_columns(view_name)

    {data_table, audit_table, entity_type, orig_primary_key} = get_audit_data(view_name)

    execute "CREATE OR REPLACE VIEW #{view_name} AS
      SELECT
          data.#{@id_name},
          #{columns},
          data.created_at,
          data.#{@created_by},
          CASE
            WHEN latest.version = 1
              THEN NULL
            ELSE
              latest.created_at
          END AS updated_at,
          CASE
            WHEN latest.version = 1
              THEN NULL
            ELSE
              latest.#{@created_by}
          END AS #{@updated_by},
          latest.version,
          latest.note
      FROM
          #{data_table}  AS data
      INNER JOIN
          #{audit_table} AS first
        ON first.#{@id_name}  = data.first_revision_#{@id_name}
      INNER JOIN
          #{audit_table} AS latest
        ON latest.#{@id_name} = data.latest_revision_#{@id_name}"

    execute "ALTER TABLE #{audit_table}
      ALTER CONSTRAINT #{audit_table}_#{orig_primary_key}_fkey
        DEFERRABLE INITIALLY DEFERRED"

    execute "ALTER TABLE #{audit_table}
      ALTER CONSTRAINT #{audit_table}_#{@created_by}_fkey
        DEFERRABLE INITIALLY DEFERRED"

    execute "CREATE TRIGGER #{view_name}_audit
      INSTEAD OF INSERT OR UPDATE OR DELETE ON #{view_name}
        FOR EACH ROW EXECUTE PROCEDURE process_audit('#{orig_primary_key}','#{entity_type}',#{columns_quoted},'note')"
  end

  def drop_audit_view(view_name) do
    execute "DROP VIEW #{view_name}"
  end

  defmacro create_audit_table(view_name, do: block) do
    {data_table, audit_table, _, orig_primary_key} = get_audit_data(view_name)

    quote do
      create table(unquote(data_table)) do
        add unquote(@id_name), unquote(@id_type),
          primary_key: true,
          null: false,
          default: {:fragment, "generate_uuid6('#{unquote(data_table)}')"}

        unquote(block)

        add unquote(@created_by), references(unquote(@users_data_table), type: unquote(@id_type)),
          null: true

        add :created_at, :utc_datetime, null: false, default: {:fragment, "now()"}
        add :deleted, :boolean, null: false, default: false
      end

      create index(unquote(data_table), unquote(@created_by), where: "deleted IS FALSE")
      create index(unquote(data_table), :created_at, where: "deleted IS FALSE")
      flush()

      create table(unquote(audit_table)) do
        add unquote(@id_name), unquote(@id_type),
          primary_key: true,
          null: false,
          default: {:fragment, "generate_uuid6('#{unquote(audit_table)}')"}

        unquote(block)

        add unquote(orig_primary_key), references(unquote(data_table), type: unquote(@id_type)),
          null: false

        add unquote(@created_by), references(unquote(@users_data_table), type: unquote(@id_type)),
          null: true

        add :version, :integer, null: false, default: "1"
        add :created_at, :utc_datetime, null: false, default: {:fragment, "now()"}
        add :note, :string
        add :deleted, :boolean, null: false, default: false
      end

      create index(unquote(audit_table), unquote(@created_by), where: "deleted IS FALSE")
      create index(unquote(audit_table), :created_at, where: "deleted IS FALSE")

      create unique_index(unquote(audit_table), [unquote(orig_primary_key), :version],
               where: "deleted IS FALSE"
             )

      alter table(unquote(data_table)) do
        add unquote(@first_revision), references(unquote(audit_table), type: unquote(@id_type)),
          null: false

        add unquote(@latest_revision), references(unquote(audit_table), type: unquote(@id_type)),
          null: false
      end

      create index(unquote(data_table), unquote(@first_revision), where: "deleted IS FALSE")
      create index(unquote(data_table), unquote(@latest_revision), where: "deleted IS FALSE")

      create_audit_view(unquote(view_name))
    end
  end

  defmacro drop_audit_table(view_name) do
    quote do
      {data_table, audit_table, _, _} = get_audit_data(unquote(view_name))

      drop table(data_table)
      drop table(audit_table)

      drop_audit_view(unquote(view_name))
    end
  end

  defmacro alter_audit_table(view_name, do: block) do
    {data_table, audit_table, _, _} = get_audit_data(view_name)

    quote do
      drop_audit_view(unquote(view_name))

      alter table(unquote(data_table)) do
        unquote(block)
      end

      flush()

      alter table(unquote(audit_table)) do
        unquote(block)
      end

      flush()

      create_audit_view(unquote(view_name))
    end
  end
end
