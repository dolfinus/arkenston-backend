defmodule Arkenston.Repo.Migration do
  use Ecto.Migration
  import Inflex

  @id_name Application.get_env(:arkenston, Arkenston.Repo)[:migration_primary_key][:name]
  @id_type Application.get_env(:arkenston, Arkenston.Repo)[:migration_primary_key][:type]

  defmacro create_audit_table(view_name, do: block) do

    # Get table column names
    {_, _, lines} = block
    columns_list = lines |> Enum.map(fn(line) ->
      case line do
      {:add, _, [column | _]} ->
        column
      end
    end)

    columns        = columns_list |> Enum.map(fn(column) -> "data.#{column}" end) |> Enum.join(",")
    columns_quoted = columns_list |> Enum.map(fn(column) -> "'#{column}'" end)    |> Enum.join(",")

    data_table       = "#{view_name}_data"  |> String.to_atom()
    audit_table      = "#{view_name}_audit" |> String.to_atom()
    entity_type      = singularize(view_name)
    orig_primary_key = "#{entity_type}_#{@id_name}" |> String.to_atom()
    created_by       = "created_by_#{@id_name}"     |> String.to_atom()
    updated_by       = "updated_by_#{@id_name}"     |> String.to_atom()
    first_revision   = "first_revision_#{@id_name}" |> String.to_atom()
    latest_revision  = "latest_revision_#{@id_name}"|> String.to_atom()

    users_data_table = "users_data"

    quote do
      create table(unquote(data_table)) do
        unquote(block)
        add unquote(created_by), references(unquote(users_data_table), type: unquote(@id_type)), null: true
        add :created_at, :utc_datetime, null: false, default: {:fragment, "now()"}
      end
      create index(unquote(data_table), unquote(created_by))
      create index(unquote(data_table), :created_at)
      flush()

      create table(unquote(audit_table)) do
        unquote(block)
        add unquote(orig_primary_key), references(unquote(data_table), type: unquote(@id_type)), null: false
        add unquote(created_by), references(unquote(users_data_table), type: unquote(@id_type)), null: true
        add :version,    :integer, null: false, default: "1"
        add :created_at, :utc_datetime, null: false, default: {:fragment, "now()"}
        add :note,       :string
      end

      create index(unquote(audit_table), unquote(created_by))
      create index(unquote(audit_table), :created_at)
      create unique_index(unquote(audit_table), [unquote(orig_primary_key), :version])

      alter table(unquote(data_table)) do
        add unquote(first_revision),  references(unquote(audit_table), type: unquote(@id_type)), null: false
        add unquote(latest_revision), references(unquote(audit_table), type: unquote(@id_type)), null: false
      end

      create index(unquote(data_table), unquote(first_revision))
      create index(unquote(data_table), unquote(latest_revision))

      execute "CREATE OR REPLACE VIEW #{unquote(view_name)} AS
        SELECT
            data.#{unquote(@id_name)},
            #{unquote(columns)},
            data.created_at,
            data.#{unquote(created_by)},
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
                latest.#{unquote(created_by)}
            END AS #{unquote(updated_by)},
            latest.version,
            latest.note
        FROM
            #{unquote(data_table)}  AS data
        INNER JOIN
            #{unquote(audit_table)} AS first
          ON first.#{unquote(@id_name)}  = data.first_revision_#{unquote(@id_name)}
        INNER JOIN
            #{unquote(audit_table)} AS latest
          ON latest.#{unquote(@id_name)} = data.latest_revision_#{unquote(@id_name)}"

      execute "ALTER TABLE #{unquote(audit_table)}
        ALTER CONSTRAINT #{unquote(audit_table)}_#{unquote(orig_primary_key)}_fkey
          DEFERRABLE INITIALLY DEFERRED"

      execute "ALTER TABLE #{unquote(audit_table)}
        ALTER CONSTRAINT #{unquote(audit_table)}_#{unquote(created_by)}_fkey
          DEFERRABLE INITIALLY DEFERRED"

      execute "CREATE TRIGGER #{unquote(view_name)}_audit
        INSTEAD OF INSERT OR UPDATE OR DELETE ON #{unquote(view_name)}
          FOR EACH ROW EXECUTE PROCEDURE process_audit('#{unquote(orig_primary_key)}','#{unquote(entity_type)}',#{unquote(columns_quoted)},'note')"
    end
  end

  defmacro drop_audit_table(view_name) do
    data_table  = "#{view_name}_data"  |> String.to_atom()
    audit_table = "#{view_name}_audit" |> String.to_atom()

    quote do
      drop table(unquote(data_table))
      drop table(unquote(audit_table))

      execute "DROP VIEW #{unquote(view_name)}"
    end
  end
end
