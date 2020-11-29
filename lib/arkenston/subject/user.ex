defmodule Arkenston.Subject.User do
  use Ecto.Schema
  import Ecto.Changeset
  import Arkenston.Schema

  use Arkenston.Helper.StructHelper

  alias Arkenston.Subject.Author

  import EctoEnum
  defenum RoleEnum, user: 0, moderator: 1, admin: 2

  @type id :: Ecto.UUID.t()
  @type role :: RoleEnum.t()
  @type password :: String.t() | nil
  @type deleted :: boolean
  @type author :: Author.t() | nil
  @type created_at :: DateTime.t()
  @type created_by :: __MODULE__.t() | nil
  @type updated_at :: DateTime.t()
  @type updated_by :: __MODULE__.t() | nil
  @type version :: number
  @type note :: String.t() | nil

  @type t :: %__MODULE__{
          id: id,
          role: role,
          password: password,
          deleted: deleted,
          author: author,
          created_at: created_at,
          created_by: created_by,
          updated_at: updated_at,
          updated_by: updated_by,
          version: version,
          note: note
        }

  audited_schema "users" do
    field :role, RoleEnum
    field :password, :string, virtual: true
    field :password_hash, :string

    belongs_to :author, Author
  end

  @password_length Application.compile_env(:arkenston, [:users, :length, :password])

  @doc false
  @spec create_changeset(attrs :: map) :: Ecto.Changeset.t()
  def create_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, [:author_id, :role, :password, :note])
    |> put_password_hash()
    |> put_role()
    |> validate_required([:author_id, :role, :password_hash])
    |> unique_constraint(:author, name: :users_data_author_id_index)
  end

  @spec update_changeset(user :: t, attrs :: map) :: Ecto.Changeset.t()
  @doc false
  def update_changeset(user, attrs \\ %{}) do
    user
    |> cast(attrs, [:author_id, :role, :password, :password_hash, :note])
    |> put_password_hash()
    |> put_role()
    |> validate_required([:author_id, :role, :password_hash])
    |> unique_constraint(:author, name: :users_data_author_id_index)
  end

  @doc false
  @spec delete_changeset(user :: t, attrs :: map) :: Ecto.Changeset.t()
  def delete_changeset(user, attrs \\ %{}) do
    user
    |> update_changeset(attrs)
    |> change(deleted: true)
  end

  @spec check_password(user :: t, password :: String.t()) :: boolean
  def check_password(user, password) do
    alg =
      case user.password_hash do
        "$pbkdf2" <> _ ->
          :pbkdf2

        _ ->
          :argon2
      end

    check_password(user, password, alg)
  end

  @spec check_password(user :: t, password :: String.t(), alg :: atom) :: boolean
  def check_password(user, password, :argon2) do
    Argon2.verify_pass(password, user.password_hash)
  end

  def check_password(user, password, :pbkdf2) do
    Pbkdf2.verify_pass(password, user.password_hash)
  end

  @spec calc_password_hash(password :: String.t(), alg :: atom) :: binary
  def calc_password_hash(password) do
    calc_password_hash(password, :argon2)
  end

  def calc_password_hash(password, :argon2) do
    Argon2.hash_pwd_salt(password)
  end

  def calc_password_hash(password, :pbkdf2) do
    Pbkdf2.hash_pwd_salt(password)
  end

  defp put_role(%Ecto.Changeset{valid?: true, changes: %{role: role}} = changeset)
       when not is_nil(role) do
    changeset
  end

  defp put_role(changeset) do
    change(changeset, %{role: :user})
  end

  defp put_password_hash(
         %Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset
       )
       when is_binary(password) do
    changeset
    |> validate_length(:password, min: @password_length)
    |> change(%{password_hash: calc_password_hash(password)})
  end

  defp put_password_hash(changeset), do: changeset
end
