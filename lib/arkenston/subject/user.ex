defmodule Arkenston.Subject.User do
  use Ecto.Schema
  import Ecto.Changeset
  import Arkenston.Schema
  import EctoEnum
  defenum RoleEnum, anonymous: -1, user: 0, moderator: 1, admin: 2

  audited_schema "users" do
    field :name,          :string
    field :role,          RoleEnum
    field :email,         :string
    field :password,      :string, virtual: true
    field :password_hash, :string
  end

  @config Application.get_env(:arkenston, :users)
  @name_format  @config[:format][:name]
  @email_format @config[:format][:email]

  @doc false
  def create_changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :role, :email, :password])
    |> put_password_hash()
    |> validate_required([:name, :role, :email, :password_hash])
    |> validate_format(:name,  @name_format)
    |> validate_format(:email, @email_format)
    |> unique_constraint(:name)
    |> unique_constraint(:email)
  end

  @doc false
  def update_changeset(user, attrs \\ %{}) do
    user
    |> cast(attrs, [:name, :role, :email, :password, :password_hash])
    |> put_password_hash()
    |> validate_required([:name, :role, :email, :password_hash])
    |> validate_format(:name,  @name_format)
    |> validate_format(:email, @email_format)
    |> unique_constraint(:name)
    |> unique_constraint(:email)
  end

  @doc false
  def delete_changeset(user) do
    user
    |> update_changeset()
    |> change([deleted: true])
  end

  def check_password(user, password) do
    Argon2.verify_pass(password, user.password_hash)
  end

  def calc_password_hash(password) do
    Argon2.hash_pwd_salt(password)
  end

  defp put_password_hash(%Ecto.Changeset{valid?: true, changes:
    %{password: password}} = changeset) when password != nil do
    change(changeset, %{password_hash: calc_password_hash(password)})
  end

  defp put_password_hash(changeset), do: changeset
end
