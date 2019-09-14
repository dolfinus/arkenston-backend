defmodule Arkenston.Repo.Migrations.CreateUsersAudit do
  use Ecto.Migration
  import Arkenston.Repo.Migration

  def up do
    create_audit_function()
  end

  def down do
    drop_audit_function()
  end
end
