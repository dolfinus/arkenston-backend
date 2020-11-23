defmodule Arkenston.Repo.Migrations.AlterAuthors do
  use Ecto.Migration

  def change do
    drop_if_exists unique_index(:authors_data, :name)
    drop_if_exists unique_index(:authors_data, :email)

    create unique_index(:authors_data, ["(lower(name))"],  name: :authors_data_name_index,  where: "deleted IS FALSE")
    create unique_index(:authors_data, ["(lower(email))"], name: :authors_data_email_index, where: "deleted IS FALSE")
  end
end
