defmodule Arkenston.Repo.Migrations.CreateUsersAudit do
  use Ecto.Migration

  def up do
    config = Application.get_env(:arkenston, :users)

    execute "CREATE OR REPLACE FUNCTION process_audit() RETURNS TRIGGER AS $audit$
      DECLARE
        audit_table_name   text   := TG_TABLE_NAME || '_audit';
        orig_table_key     text   := TG_ARGV[0];
        orig_table_columns text[];
        new_table_columns  text[];
        new_version        int    := 1;
        latest_revision_id int;
      BEGIN
        -- Get original table column names excluding 'id'
        FOR i IN 1..TG_NARGS-1
        LOOP
          new_table_columns  = array_append(new_table_columns,  TG_ARGV[i]);
          orig_table_columns = array_append(orig_table_columns, FORMAT('($1).%1$I', TG_ARGV[i]));
        END LOOP;

        IF (TG_OP = 'UPDATE') THEN
          EXECUTE FORMAT(
            'SELECT
                rev.version + 1 AS new_version
            FROM
                %1$I AS rev,
                %2$I AS orig
            WHERE
                rev.id = orig.latest_revision_id',
            audit_table_name,
            TG_TABLE_NAME
          )
          INTO new_version;
        END IF;

        EXECUTE FORMAT(
          'INSERT INTO %1$I (
            id,
            version,
            created_by_id,
            created_at,
            %3$I,
            %5$s
          )

          SELECT
            NEXTVAL(pg_get_serial_sequence(''%1$I'', ''id'')) AS id,
            %2$s AS version,
            COALESCE(current_setting(''arkenston.current_user'', ''t'')::integer, #{config[:anonymous][:id]}) AS created_by_id,
            now() AS created_at,
            ($1).id AS %3$I,
            %4$s
          RETURNING id
          ',
          audit_table_name,
          new_version,
          orig_table_key,
          array_to_string(orig_table_columns, ',\n'),
          array_to_string(new_table_columns,  ',\n')
        )
        INTO  latest_revision_id
        USING NEW;

        NEW.latest_revision_id = latest_revision_id;
        IF (TG_OP = 'INSERT') THEN
          NEW.first_revision_id = latest_revision_id;
        END IF;
        RETURN NEW;
      END;

    $audit$ LANGUAGE plpgsql"
  end

  def down do
    execute "DROP FUNCTION process_audit()"
  end
end
