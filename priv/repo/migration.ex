defmodule Arkenston.Repo.Migration do
  use Ecto.Migration
  import Inflex

  @id_name Application.get_env(:arkenston, Arkenston.Repo)[:migration_primary_key][:name]
  @id_type Application.get_env(:arkenston, Arkenston.Repo)[:migration_primary_key][:type]
  @anonymous_id Application.get_env(:arkenston, :users)[:anonymous][@id_name]

  defmacro create_audit_table(orig_table, do: block) do

    # Get table column names
    {_, _, lines} = block
    columns = lines |> Enum.map(fn(line) ->
      case line do
      {:add, _, [column | _]} ->
        "'#{column}'"
      end
    end) |> Enum.join(",")

    audit_table      = "#{orig_table}_audit"           |> String.to_atom()
    orig_primary_key = "#{singularize(orig_table)}_id" |> String.to_atom()
    created_by       = "created_by_#{@id_name}"        |> String.to_atom()
    first_revision   = "first_revision_#{@id_name}"    |> String.to_atom()
    latest_revision  = "latest_revision_#{@id_name}"   |> String.to_atom()

    quote do
      create table(unquote(orig_table)) do
        unquote(block)
      end
      flush()

      create table(unquote(audit_table)) do
        unquote(block)
        add unquote(orig_primary_key), references(unquote(orig_table), type: unquote(@id_type)), null: false
        add unquote(created_by), references("users", type: unquote(@id_type)), null: false, default: unquote(@anonymous_id)
        add :version,    :integer, null: false, default: "1"
        add :created_at, :utc_datetime, null: false, default: {:fragment, "now()"}
      end

      create index(unquote(audit_table), unquote(created_by))
      create index(unquote(audit_table), :created_at)
      create unique_index(unquote(audit_table), [unquote(orig_primary_key), :version], where: "deleted IS FALSE")

      alter table(unquote(orig_table)) do
        add unquote(first_revision),  references(unquote(audit_table), type: unquote(@id_type)), null: false
        add unquote(latest_revision), references(unquote(audit_table), type: unquote(@id_type)), null: false
      end

      create index(unquote(orig_table), unquote(first_revision))
      create index(unquote(orig_table), unquote(latest_revision))

      execute "ALTER TABLE #{unquote(audit_table)}
        ALTER CONSTRAINT #{unquote(audit_table)}_#{unquote(orig_primary_key)}_fkey
          DEFERRABLE INITIALLY DEFERRED"

      execute "ALTER TABLE #{unquote(audit_table)}
        ALTER CONSTRAINT #{unquote(audit_table)}_#{unquote(created_by)}_fkey
          DEFERRABLE INITIALLY DEFERRED"

      execute "CREATE TRIGGER #{unquote(orig_table)}_audit
        BEFORE INSERT OR UPDATE ON #{unquote(orig_table)}
          FOR EACH ROW EXECUTE PROCEDURE process_audit('#{unquote(orig_primary_key)}',#{unquote(columns)})"
    end
  end

  defmacro drop_audit_table(orig_table) do
    audit_table = "#{orig_table}_audit" |> String.to_atom()

    quote do
      drop table(unquote(orig_table))
      drop table(unquote(audit_table))
    end
  end
end
