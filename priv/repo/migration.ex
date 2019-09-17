defmodule Arkenston.Repo.Migration do
  use Ecto.Migration
  import Inflex

  defmacro create_audit(table, do: block) do

    # Get table column names
    {_, _, lines} = block
    columns = lines |> Enum.map(fn(line) ->
      case line do
      {:add, _, [column | _]} ->
        "'#{column}'"
      end
    end) |> Enum.join(",")

    quote do
      orig_table       = unquote(table).name             |> String.to_atom()
      new_table        = "#{orig_table}_audit"           |> String.to_atom()
      orig_primary_key = "#{singularize(orig_table)}_id" |> String.to_atom()

      create unquote(table) do
        unquote(block)
      end
      flush()

      create %{unquote(table) | name: new_table} do
        unquote(block)
        add orig_primary_key, references(orig_table)
        add :created_by_id,   references("users")
        add :version,         :integer
        add :created_at,      :utc_datetime, default: "now()"
      end

      alter unquote(table) do
        add :first_revision_id,  references(new_table)
        add :latest_revision_id, references(new_table)
      end

      create index(orig_table, :first_revision_id)
      create index(orig_table, :latest_revision_id)
      create index(new_table,  :created_by_id)
      create index(new_table,  [orig_primary_key, :version, :created_at])

      execute "ALTER TABLE #{new_table}
        ALTER CONSTRAINT #{new_table}_#{orig_primary_key}_fkey
          DEFERRABLE INITIALLY DEFERRED"

      execute "ALTER TABLE #{new_table}
        ALTER CONSTRAINT #{new_table}_created_by_id_fkey
          DEFERRABLE INITIALLY DEFERRED"

      execute "CREATE TRIGGER #{orig_table}_audit
        BEFORE INSERT OR UPDATE ON #{orig_table}
          FOR EACH ROW EXECUTE PROCEDURE process_audit('#{orig_primary_key}',#{unquote(columns)})"
    end
  end

  defmacro drop_audit(table) do
    quote do
      orig_table = unquote(table).name   |> String.to_atom()
      new_table  = "#{orig_table}_audit" |> String.to_atom()

      drop table orig_table
      drop table new_table
    end
  end
end
