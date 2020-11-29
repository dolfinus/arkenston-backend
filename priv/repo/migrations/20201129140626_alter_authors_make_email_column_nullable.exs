defmodule Arkenston.Repo.Migrations.AlterAuthorsMakeEmailColumnNullable do
  use Ecto.Migration
  import Arkenston.Repo.Migration

  def change do
    alter_audit_table :authors do
      modify(:email, :string, null: true, from: :string)
    end

    drop_if_exists unique_index(:authors_data, ["(lower(email))"], name: :authors_data_email_index)

    create unique_index(:authors_data, ["(lower(email))"],
             name: :authors_data_email_index,
             where: "deleted IS FALSE and email IS NOT NULL"
           )
  end
end
