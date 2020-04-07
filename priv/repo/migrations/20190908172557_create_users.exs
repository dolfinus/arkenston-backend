defmodule Arkenston.Repo.Migrations.CreateUsers do
  use Ecto.Migration
  import Arkenston.Repo.Migration

  def up do
    create_audit_table :users do
      add :name,          :string,  null: false
      add :email,         :string,  null: false
      add :role,          :integer, null: false, default: 0
      add :password_hash, :string
      add :deleted,       :boolean, null: false, default: false
    end

    create unique_index(:users, :role,  where: "role < 0")
    create unique_index(:users, :name,  where: "deleted IS FALSE")
    create unique_index(:users, :email, where: "deleted IS FALSE")
    create index(:users, [:id, :role],  where: "deleted IS FALSE")
    create index(:users, [:id, :name,  :role], where: "deleted IS FALSE")
    create index(:users, [:id, :email, :role], where: "deleted IS FALSE")
  end

  def down do
    drop_audit_table :users
  end
end
