defmodule Arkenston.Repo.Migrations.CreateUsers do
  use Ecto.Migration
  import Arkenston.Repo.Migration

  def up do
    create_audit_table :users do
      add :name,          :string,  null: false
      add :role,          :integer, null: false
      add :email,         :string,  null: false
      add :password_hash, :string
      add :deleted,       :boolean, null: false, default: false
    end

    create unique_index(:users, :name)
    create unique_index(:users, :email)
    create index(:users, [:id, :role,  :deleted])
    create index(:users, [:id, :name,  :role, :deleted])
    create index(:users, [:id, :email, :role, :deleted])
  end

  def down do
    drop_audit_table :users
  end
end
