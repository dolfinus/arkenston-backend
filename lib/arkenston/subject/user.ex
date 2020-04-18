defmodule Arkenston.Subject.User do
  use Ecto.Schema
  import Ecto.Changeset
  import Arkenston.Schema
  import EctoEnum
  defenum RoleEnum, user: 0, moderator: 1, admin: 2

  @type id :: Ecto.UUID.t
  @type name :: String.t
  @type role :: RoleEnum.t
  @type email :: String
  @type password :: String.t
  @type deleted :: boolean

  @type t :: %__MODULE__{
    id: id,
    name: name,
    role: role,
    email: email,
    password: password,
    deleted: deleted
  }

  audited_schema "users" do
    field :name,          :string
    field :role,          RoleEnum
    field :email,         :string
    field :password,      :string, virtual: true
    field :password_hash, :string
    field :deleted,       :boolean
  end

  @config Application.get_env(:arkenston, :users)
  @name_format  @config[:format][:name]
  @email_format @config[:format][:email]

  @doc false
  def create_changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :role, :email, :password])
    |> put_password_hash()
    |> put_role()
    |> validate_required([:name, :role, :email, :password_hash])
    |> validate_format(:name,  @name_format)
    |> validate_format(:email, @email_format)
    |> unique_constraint(:name)
    |> unique_constraint(:email)
    |> unique_constraint(:role)
  end

  @doc false
  def update_changeset(user, attrs \\ %{}) do
    user
    |> cast(attrs, [:name, :role, :email, :password, :password_hash])
    |> put_password_hash()
    |> put_role()
    |> validate_required([:name, :role, :email, :password_hash])
    |> validate_format(:name,  @name_format)
    |> validate_format(:email, @email_format)
    |> unique_constraint(:name)
    |> unique_constraint(:email)
    |> unique_constraint(:role)
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

  defp put_role(%Ecto.Changeset{valid?: true, changes:
    %{role: role}} = changeset) when not is_nil(role) do
    changeset
  end

  defp put_role(changeset) do
    change(changeset, %{role: :user})
  end

  defp put_password_hash(%Ecto.Changeset{valid?: true, changes:
    %{password: password}} = changeset) when not is_nil(password) do
    change(changeset, %{password_hash: calc_password_hash(password)})
  end

  defp put_password_hash(changeset), do: changeset
end
