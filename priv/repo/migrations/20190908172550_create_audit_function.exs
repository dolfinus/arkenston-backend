defmodule Arkenston.Repo.Migrations.CreateAuditFunction do
  use Ecto.Migration
  @id_name Application.get_env(:arkenston, Arkenston.Repo)[:primary_key][:name]

  def up do
    execute "CREATE EXTENSION IF NOT EXISTS \"pgcrypto\";"

    execute "
    CREATE OR REPLACE FUNCTION generate_uuid6(p_node bigint) RETURNS UUID AS $func$
    DECLARE
      i        integer;
      v_rnd    float8;
      v_byte   bit(8);
      v_bytes  bytea;
      v_uuid   varchar;

      v_time timestamp with time zone:= null;
      v_secs bigint := null;
      v_msec bigint := null;
      v_timestamp bigint := null;
      v_timestamp_hex varchar := null;
      v_variant varchar;
      v_node varchar;

      c_node_max bigint := (2^48)::bigint; -- 6 bytes
      c_greg bigint :=  -12219292800; -- Gragorian epoch: '1582-10-15 00:00:00'
    BEGIN

      -- Get time and random values
      v_time := clock_timestamp();
      v_rnd := random();

      -- Extract seconds and microseconds
      v_secs := EXTRACT(EPOCH FROM v_time);
      v_msec := mod(EXTRACT(MICROSECONDS FROM v_time)::numeric, 10^6::numeric); -- MOD() to remove seconds

      -- Calculate the timestamp
      v_timestamp := (((v_secs - c_greg) * 10^6) + v_msec) * 10;

      -- Generate timestamp hexadecimal (and set version number)
      v_timestamp_hex := lpad(to_hex(v_timestamp), 16, '0');
      v_timestamp_hex := substr(v_timestamp_hex, 2, 12) || '6' || substr(v_timestamp_hex, 14, 3);

      -- Generate a random hexadecimal
      v_uuid := md5(v_time::text || v_rnd::text);

      -- Concat timestemp hex with random hex
      v_uuid := v_timestamp_hex || substr(v_uuid, 1, 16);

      -- Insert the node identifier
      if p_node is not null then

        v_node := to_hex(p_node % c_node_max);
        v_node := lpad(v_node, 12, '0');
        v_uuid := overlay(v_uuid placing v_node from 21);

      end if;

      -- Set variant number
      v_bytes := decode(substring(v_uuid, 17, 2), 'hex');
      v_byte := get_byte(v_bytes, 0)::bit(8);
      v_byte := v_byte & x'3f';
      v_byte := v_byte | x'80';
      v_bytes := set_byte(v_bytes, 0, v_byte::integer);
      v_variant := encode(v_bytes, 'hex')::varchar;
      v_uuid := overlay(v_uuid placing v_variant from 17);

      -- Set multicast bit
      v_bytes := decode(substring(v_uuid, 21, 2), 'hex');
      v_byte := get_byte(v_bytes, 0)::bit(8);
      v_byte := v_byte | x'01';
      v_bytes := set_byte(v_bytes, 0, v_byte::integer);
      v_variant := encode(v_bytes, 'hex')::varchar;
      v_uuid := overlay(v_uuid placing v_variant from 21);

      return v_uuid::uuid;
    END;
    $func$ LANGUAGE plpgsql"

    execute "
    CREATE OR REPLACE FUNCTION generate_uuid6(entity_name VARCHAR(4000)) RETURNS UUID AS $func$
    DECLARE
      domain varchar(12);
      tmp    varchar(36);
      result uuid;
    BEGIN
      domain := left(encode(digest(entity_name, 'sha1'), 'hex'), 12);
      tmp    := left(gen_random_uuid()::varchar, 24);
      result := (tmp || domain)::uuid;

      RETURN result;
    END;
    $func$ LANGUAGE plpgsql"

    execute "
      CREATE OR REPLACE FUNCTION process_audit() RETURNS TRIGGER AS $audit$
      DECLARE
        view_name               text := TG_TABLE_NAME;
        data_table_name         text := TG_TABLE_NAME || '_data';
        audit_table_name        text := TG_TABLE_NAME || '_audit';
        orig_table_key          text := TG_ARGV[0];
        entity_name             text := TG_ARGV[1];
        revision_name           text := TG_ARGV[1] || '_revision';
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
          NEW.#{@id_name} := generate_uuid6(entity_name);
        END IF;

        IF current_setting('arkenston.current_user', 't') IS NOT NULL AND current_setting('arkenston.current_user', 't') != '' THEN
          current_user_#{@id_name} := current_setting('arkenston.current_user', 't');
        END IF;

        -- Get original table column names excluding '#{@id_name}'
        FOR i IN 2..TG_NARGS-1
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
              #{@id_name},
              %4$I,
              %6$s,
              version,
              created_by_#{@id_name}
            )

            VALUES (
              ''%2$s''::uuid,
              ($1).#{@id_name},
              %5$s,
              %3$s,
              ''%7$s''::uuid
            )
            RETURNING #{@id_name}
            ',
            audit_table_name,
            generate_uuid6(revision_name),
            new_version,
            orig_table_key,
            array_to_string(all_orig_table_columns, ',\n'),
            array_to_string(all_audit_table_columns,  ',\n'),
            current_user_#{@id_name}
          );
        ELSE
          audit_statement := FORMAT(
            'INSERT INTO %1$I (
              #{@id_name},
              %4$I,
              %6$s,
              version
            )

            VALUES (
              ''%2$s''::uuid,
              ($1).#{@id_name},
              %5$s,
              %3$s
            )
            RETURNING #{@id_name}
            ',
            audit_table_name,
            generate_uuid6(revision_name),
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
          IF current_user_#{@id_name} IS NOT NULL THEN
            data_statement := FORMAT(
              'INSERT INTO %1$I (
                #{@id_name},
                %3$s,
                first_revision_#{@id_name},
                latest_revision_#{@id_name},
                created_by_#{@id_name}
              )

              VALUES (
                ($1).#{@id_name},
                %4$s,
                ($2),
                ($2),
                ''%5$s''::uuid
              )
              RETURNING #{@id_name}
              ',
              data_table_name,
              orig_table_key,
              array_to_string(audit_table_columns, ',\n'),
              array_to_string(orig_table_columns,  ',\n'),
              current_user_#{@id_name}
            );
          ELSE
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
          END IF;
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
    execute "DROP FUNCTION generate_uuid6()"
  end
end
