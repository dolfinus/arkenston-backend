defmodule Arkenston.Repo.Migrations.CreateUsersAudit do
  use Ecto.Migration
  @id_name Application.get_env(:arkenston, Arkenston.Repo)[:migration_primary_key][:name]

  def up do
    execute "CREATE EXTENSION IF NOT EXISTS \"pgcrypto\";"
    execute "CREATE OR REPLACE FUNCTION process_audit() RETURNS TRIGGER AS $audit$
      DECLARE
        audit_table_name   text   := TG_TABLE_NAME || '_audit';
        orig_table_key     text   := TG_ARGV[0];
        current_user_#{@id_name} uuid := current_setting('arkenston.current_user', 't');
        orig_table_columns text[];
        new_table_columns  text[];
        new_version        int    := 1;
        latest_revision_#{@id_name} uuid;
        version_statement  text := '';
        audit_statement    text := '';
      BEGIN
        -- Get original table column names excluding 'id'
        FOR i IN 1..TG_NARGS-1
        LOOP
          new_table_columns  = array_append(new_table_columns,  TG_ARGV[i]);
          orig_table_columns = array_append(orig_table_columns, FORMAT('($1).%1$I', TG_ARGV[i]));
        END LOOP;

        IF (TG_OP = 'UPDATE') THEN
          version_statement := FORMAT(
            'SELECT
                rev.version + 1 AS new_version
            FROM
                %1$s AS rev,
                %2$s AS orig
            WHERE
                rev.id = orig.latest_revision_#{@id_name}',
            audit_table_name,
            TG_TABLE_NAME
          );
          --RAISE LOG 'version statement sql %', version_statement;

          EXECUTE version_statement
          INTO new_version;

          --RAISE LOG 'version statement result %', new_version;
        END IF;

        -- RAISE LOG 'current user #{@id_name} %', current_user_#{@id_name};

        IF current_user_#{@id_name} IS NOT NULL THEN
          audit_statement := FORMAT(
            'INSERT INTO %1$I (
              %3$I,
              %5$s,
              version,
              created_by_#{@id_name}
            )

            SELECT
              ($1).id AS %3$I,
              %4$s,
              %2$s AS version,
              ''%6$s''::uuid AS created_by_#{@id_name}
            RETURNING id
            ',
            audit_table_name,
            new_version,
            orig_table_key,
            array_to_string(orig_table_columns, ',\n'),
            array_to_string(new_table_columns,  ',\n'),
            current_user_#{@id_name}
          );
        ELSE
          audit_statement := FORMAT(
            'INSERT INTO %1$I (
              %3$I,
              %5$s,
              version
            )

            SELECT
              ($1).id AS %3$I,
              %4$s,
              %2$s AS version
            RETURNING id
            ',
            audit_table_name,
            new_version,
            orig_table_key,
            array_to_string(orig_table_columns, ',\n'),
            array_to_string(new_table_columns,  ',\n')
          );
        END IF;

        --RAISE LOG 'audit statement sql %', audit_statement;

        EXECUTE  audit_statement
        INTO  latest_revision_#{@id_name}
        USING NEW;

        --RAISE LOG 'audit statement result %', latest_revision_#{@id_name};

        NEW.latest_revision_#{@id_name} = latest_revision_#{@id_name};
        IF (TG_OP = 'INSERT') THEN
          NEW.first_revision_#{@id_name} = latest_revision_#{@id_name};
        END IF;

        NEW.note = null;

        RETURN NEW;
      END;

    $audit$ LANGUAGE plpgsql"
  end

  def down do
    execute "DROP FUNCTION process_audit()"
  end
end
