defmodule Arkenston.Repo.Migrations.CreateUsers do
  use Ecto.Migration
  import Arkenston.Repo.Migration

  def up do
    create_audit table(:users) do
      add :name,                :string
      add :role,                :integer
      add :email,               :string
      add :password_hash,       :string
      add :confirmation_token,  :string
      add :remember_token,      :string
      add :deleted,             :boolean, default: false
    end

    create unique_index(:users, :name)
    create unique_index(:users, :email)
    create index(:users, [:id, :name,  :role])
    create index(:users, [:id, :email, :role])
  end

  def down do
    drop_audit table(:users)
  end
end
