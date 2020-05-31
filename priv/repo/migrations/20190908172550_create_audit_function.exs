defmodule Arkenston.Repo.Migrations.CreateUsersAudit do
  use Ecto.Migration
  @id_name Application.get_env(:arkenston, Arkenston.Repo)[:migration_primary_key][:name]

  def up do
    execute "CREATE EXTENSION IF NOT EXISTS \"pgcrypto\";"
    execute "CREATE OR REPLACE FUNCTION process_audit() RETURNS TRIGGER AS $audit$
      DECLARE
        view_name               text := TG_TABLE_NAME;
        data_table_name         text := TG_TABLE_NAME || '_data';
        audit_table_name        text := TG_TABLE_NAME || '_audit';
        orig_table_key          text := TG_ARGV[0];
        current_user_#{@id_name} uuid;
        audit_table_columns     text[];
        orig_table_columns      text[];
        all_orig_table_columns  text[];
        all_audit_table_columns text[];
        new_version             int    := 1;
        latest_revision_#{@id_name} uuid;
        result_#{@id_name}      uuid;
        result_row              record;
        version_statement       text := '';
        audit_statement         text := '';
        data_statement          text := '';
        return_statement        text := '';
      BEGIN
        IF NEW.deleted IS NULL THEN
          NEW.deleted := false;
        END IF;

        IF (TG_OP = 'INSERT') THEN
          NEW.#{@id_name} := gen_random_uuid();
        END IF;

        IF current_setting('arkenston.current_user', 't') IS NOT NULL AND current_setting('arkenston.current_user', 't') != '' THEN
          current_user_#{@id_name} := current_setting('arkenston.current_user', 't');
        END IF;

        -- Get original table column names excluding '#{@id_name}'
        FOR i IN 1..TG_NARGS-1
        LOOP
          all_audit_table_columns = array_append(all_audit_table_columns, TG_ARGV[i]);
          all_orig_table_columns  = array_append(all_orig_table_columns, FORMAT('($1).%1$I', TG_ARGV[i]));

          IF TG_ARGV[i] NOT IN ('note') THEN
            audit_table_columns = array_append(audit_table_columns, TG_ARGV[i]);
            orig_table_columns  = array_append(orig_table_columns, FORMAT('($1).%1$I', TG_ARGV[i]));
          END IF;
        END LOOP;

        IF (TG_OP = 'UPDATE') THEN
          version_statement := FORMAT(
            'SELECT
                rev.version + 1
            FROM
                %1$s AS rev,
                %2$s AS data
            WHERE
                rev.#{@id_name}  = data.latest_revision_#{@id_name}
            AND data.#{@id_name} = ($1).#{@id_name}',
            audit_table_name,
            data_table_name
          );
          --RAISE LOG 'version statement sql %', version_statement;

          EXECUTE
            version_statement
          INTO
            new_version
          USING NEW;

          --RAISE LOG 'version statement result %', new_version;
        END IF;

        --RAISE LOG 'current user #{@id_name} %', current_user_#{@id_name};

        IF current_user_#{@id_name} IS NOT NULL THEN
          audit_statement := FORMAT(
            'INSERT INTO %1$I (
              %3$I,
              %5$s,
              version,
              created_by_#{@id_name}
            )

            VALUES (
              ($1).#{@id_name},
              %4$s,
              %2$s,
              ''%6$s''::uuid
            )
            RETURNING #{@id_name}
            ',
            audit_table_name,
            new_version,
            orig_table_key,
            array_to_string(all_orig_table_columns, ',\n'),
            array_to_string(all_audit_table_columns,  ',\n'),
            current_user_#{@id_name}
          );
        ELSE
          audit_statement := FORMAT(
            'INSERT INTO %1$I (
              %3$I,
              %5$s,
              version
            )

            VALUES (
              ($1).#{@id_name},
              %4$s,
              %2$s
            )
            RETURNING #{@id_name}
            ',
            audit_table_name,
            new_version,
            orig_table_key,
            array_to_string(all_orig_table_columns, ',\n'),
            array_to_string(all_audit_table_columns,  ',\n')
          );
        END IF;

        --RAISE LOG 'audit statement sql %', audit_statement;

        EXECUTE
            audit_statement
        INTO
            latest_revision_#{@id_name}
        USING NEW;

        --RAISE LOG 'audit statement result %', latest_revision_#{@id_name};

        IF (TG_OP = 'INSERT') THEN
          data_statement := FORMAT(
            'INSERT INTO %1$I (
              #{@id_name},
              %3$s,
              first_revision_#{@id_name},
              latest_revision_#{@id_name}
            )

            VALUES (
              ($1).#{@id_name},
              %4$s,
              ($2),
              ($2)
            )
            RETURNING #{@id_name}
            ',
            data_table_name,
            orig_table_key,
            array_to_string(audit_table_columns, ',\n'),
            array_to_string(orig_table_columns,  ',\n')
          );
          --RAISE LOG 'insert statement sql %', data_statement;

          EXECUTE
            data_statement
          INTO
            result_#{@id_name}
          USING NEW, latest_revision_#{@id_name};

          --RAISE LOG 'insert statement result %', result_#{@id_name};
        ELSE
          data_statement := FORMAT(
            'UPDATE %1$I
            SET (%3$s,latest_revision_#{@id_name}) = (%4$s,($3))
            WHERE #{@id_name} = ($2).#{@id_name}
            RETURNING #{@id_name}
            ',
            data_table_name,
            orig_table_key,
            array_to_string(audit_table_columns, ',\n'),
            array_to_string(orig_table_columns,  ',\n')
          );
          --RAISE LOG 'update statement sql %', data_statement;

          EXECUTE
            data_statement
          INTO
            result_#{@id_name}
          USING NEW, OLD, latest_revision_#{@id_name};

          --RAISE LOG 'update statement result %', result_#{@id_name};
        END IF;

        return_statement := FORMAT(
            'SELECT * FROM %1$I WHERE #{@id_name} = ($1)',
            view_name
          );

        --RAISE LOG 'return statement sql %', return_statement;

        EXECUTE return_statement
        INTO result_row
        USING result_#{@id_name};

        --RAISE LOG 'return statement result %', result_row;

        RETURN result_row;
      END;

    $audit$ LANGUAGE plpgsql"
  end

  def down do
    execute "DROP FUNCTION process_audit()"
  end
end
