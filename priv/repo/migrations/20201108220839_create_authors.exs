defmodule Arkenston.Repo.Migrations.CreateAuthors do
  use Ecto.Migration
  import Arkenston.Repo.Migration

  def up do
    create_audit_table :authors do
      add :name,         :string,  null: false
      add :email,        :string,  null: false
      add :translations, :map
    end

    create unique_index(:authors_data, :name,   where: "deleted IS FALSE")
    create unique_index(:authors_data, :email,  where: "deleted IS FALSE")
  end

  def down do
    drop_audit_table :authors
  end
end
