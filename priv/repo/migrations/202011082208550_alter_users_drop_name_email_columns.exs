defmodule Arkenston.Repo.Migrations.AlterUsersDropNameEmailColumns do
  use Ecto.Migration
  import Arkenston.Repo.Migration

  @id_type Application.get_env(:arkenston, Arkenston.Repo)[:primary_key][:type]

  def change do
    alter_audit_table :users do
      add_if_not_exists(:author_id, references(:authors_data, type: unquote(@id_type)),
        null: false
      )
    end

    execute("""
      WITH migrate_names_emails as (
        INSERT INTO authors (name, email, note)
          (SELECT
            name,
            email,
            'Automatically create user authors'
          FROM users_data)
        RETURNING *
      )
      UPDATE users_data
      SET author_id = migrate_names_emails.id
      FROM migrate_names_emails
      WHERE users_data.name  = migrate_names_emails.name
      AND   users_data.email = migrate_names_emails.email
    """)

    alter_audit_table :users do
      remove_if_exists(:name, :string)
      remove_if_exists(:email, :string)
    end

    drop_if_exists unique_index(:users_data, :name)
    drop_if_exists unique_index(:users_data, :email)
    drop_if_exists index(:users_data, [:id, :name, :role])
    drop_if_exists index(:users_data, [:id, :email, :role])

    create unique_index(:users_data, :author_id, where: "deleted IS FALSE")
  end
end
