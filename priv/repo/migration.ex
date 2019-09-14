defmodule Arkenston.Repo.Migration do
  use Ecto.Migration
  import Inflex

  defmacro create_audit(table, do: block) do
    quote do
      orig_table       = unquote(table).name             |> String.to_atom()
      new_table        = "#{orig_table}_audit"           |> String.to_atom()
      orig_primary_key = "#{singularize(orig_table)}_id" |> String.to_atom()

      create unquote(table) do
        unquote(block)
        add :version, :integer
        add :deleted, :boolean, default: false
        timestamps inserted_at: false, default: "now()"
      end
      flush()

      create %{unquote(table) | name: new_table} do
        add :author_id, references("users")
        add orig_primary_key, references(orig_table)
        unquote(block)
        add :version, :integer
        add :deleted, :boolean, default: false
        timestamps updated_at: false, default: "now()"
      end

      create index(orig_table, [:id,              :version, :updated_at])
      create index(new_table,  [orig_primary_key, :version, :inserted_at])

      execute "ALTER TABLE #{new_table}
        ALTER CONSTRAINT #{new_table}_#{orig_primary_key}_fkey
          DEFERRABLE INITIALLY IMMEDIATE"

      execute "CREATE TRIGGER #{orig_table}_audit
        BEFORE INSERT OR UPDATE ON #{orig_table}
          FOR EACH ROW EXECUTE PROCEDURE process_audit()"
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

  def create_audit_function do
    config = Application.get_env(:arkenston, :users)

    execute "CREATE OR REPLACE FUNCTION process_audit() RETURNS TRIGGER AS $audit$
      DECLARE
        audit_table_name text := TG_TABLE_NAME || '_audit';
      BEGIN
          IF (TG_OP = 'UPDATE') THEN
              EXECUTE FORMAT(
                    'INSERT INTO %1$I
                    SELECT
                      NEXTVAL(pg_get_serial_sequence(''%1$I'', ''id'')),
                      COALESCE(current_setting(''arkenston.current_user'', ''t'')::integer, #{config[:anonymous][:id]}),
                      ($1).*
                    ',
                    audit_table_name)
                  USING OLD;
              NEW.version = OLD.version + 1;
              RETURN NEW;
          ELSIF (TG_OP = 'INSERT') THEN
              NEW.version = 1;
              RETURN NEW;
          END IF;
      END;

    $audit$ LANGUAGE plpgsql"
  end

  def drop_audit_function do
    execute "DROP FUNCTION process_audit()"
  end
end
