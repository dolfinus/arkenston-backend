defmodule Arkenston.Subject.User do
  use Ecto.Schema
  import Ecto.Changeset
  import Arkenston.Schema
  import EctoEnum
  defenum RoleEnum, user: 0, moderator: 1, admin: 2

  audited_schema "users" do
    field :name,               :string
    field :role,               RoleEnum
    field :email,              :string
    field :password,           :string, virtual: true
    field :password_hash,      :string
    field :confirmation_token, :string
    field :remember_token,     :string
  end


  @config Application.get_env(:arkenston, :users)
  @name_format  @config[:format][:name]
  @email_format @config[:format][:email]

  @doc false
  def create_changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :role, :email, :password, :confirmation_token, :remember_token])
    |> put_pass_hash()
    |> validate_required([:name, :role, :email, :password_hash])
    |> validate_format(:name,  @name_format)
    |> validate_format(:email, @email_format)
    |> unique_constraint(:name)
    |> unique_constraint(:email)
  end

  @doc false
  def update_changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :role, :email, :password, :password_hash, :confirmation_token, :remember_token])
    |> put_pass_hash()
    |> validate_required([:name, :role, :email])
    |> validate_format(:name,  @name_format)
    |> validate_format(:email, @email_format)
    |> unique_constraint(:name)
    |> unique_constraint(:email)
  end

  defp put_pass_hash(%Ecto.Changeset{valid?: true, changes:
    %{password: password}} = changeset) do
    change(changeset, Argon2.add_hash(password))
  end

  defp put_pass_hash(changeset), do: changeset
end
