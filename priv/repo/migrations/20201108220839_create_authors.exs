defmodule Arkenston.Repo.Migrations.CreateAuthors do
  use Ecto.Migration
  import Arkenston.Repo.Migration

  def up do
    create_audit_table :authors do
      add :name, :string, null: false
      add :email, :string, null: true
      add :translations, :map
    end

    create unique_index(:authors_data, ["(lower(name))"],
             name: :authors_data_name_index,
             where: "deleted IS FALSE"
           )

    create unique_index(:authors_data, ["(lower(email))"],
             name: :authors_data_email_index,
             where: "deleted IS FALSE and email IS NOT NULL"
           )
  end

  def down do
    drop_audit_table(:authors)
  end
end
