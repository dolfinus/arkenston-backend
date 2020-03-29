defmodule Arkenston.Repo.Migrations.CreateUsers do
  use Ecto.Migration
  import Arkenston.Repo.Migration

  def up do
    create_audit table(:users) do
      add :name,          :string
      add :role,          :integer
      add :email,         :string
      add :password_hash, :string
      add :deleted,       :boolean, default: false
    end

    create unique_index(:users, :name)
    create unique_index(:users, :email)
    create index(:users, [:id, :role,  :deleted])
    create index(:users, [:id, :name,  :role, :deleted])
    create index(:users, [:id, :email, :role, :deleted])
  end

  def down do
    drop_audit table(:users)
  end
end
