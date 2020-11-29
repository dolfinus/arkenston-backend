defmodule Arkenston.Subject.Author do
  use Ecto.Schema
  import Ecto.Changeset
  import Arkenston.Schema

  use Arkenston.Helper.StructHelper
  use Arkenston.Helper.TranslationHelper

  alias Arkenston.Subject.User

  use Trans, translates: [:first_name, :middle_name, :last_name]

  @type lang :: atom :: String.t()

  @type id :: Ecto.UUID.t()
  @type name :: String.t()
  @type email :: String.t()
  @type first_name :: String.t()
  @type middle_name :: String.t()
  @type last_name :: String.t()
  @type translations :: %{lang => first_name | middle_name | last_name}
  @type deleted :: boolean
  @type user :: User.t() | nil
  @type created_at :: DateTime.t()
  @type created_by :: __MODULE__.t() | nil
  @type updated_at :: DateTime.t()
  @type updated_by :: __MODULE__.t() | nil
  @type version :: number
  @type note :: String.t() | nil

  @type t :: %__MODULE__{
          id: id,
          name: name,
          email: email,
          first_name: first_name,
          middle_name: middle_name,
          last_name: last_name,
          translations: translations,
          deleted: deleted,
          user: user,
          created_at: created_at,
          created_by: created_by,
          updated_at: updated_at,
          updated_by: updated_by,
          version: version,
          note: note
        }

  audited_schema "authors" do
    field :name, :string
    field :email, :string
    field :first_name, :string, virtual: true
    field :middle_name, :string, virtual: true
    field :last_name, :string, virtual: true
    field :translations, :map

    has_one :user, User
  end

  @name_format Application.compile_env(:arkenston, [:authors, :format, :name])
  @email_format Application.compile_env(:arkenston, [:authors, :format, :email])

  @doc false
  @spec create_changeset(attrs :: map) :: Ecto.Changeset.t()
  def create_changeset(attrs) do
    attrs = create_translations(attrs)

    %__MODULE__{}
    |> cast(attrs, [:name, :email, :translations, :note])
    |> put_lowercase_name()
    |> put_lowercase_email()
    |> validate_required([:name])
    |> validate_format(:name, @name_format)
    |> validate_format(:email, @email_format)
    |> unique_constraint(:name, name: :authors_data_name_index)
    |> unique_constraint(:email, name: :authors_data_email_index)
  end

  @spec update_changeset(user :: t, attrs :: map) :: Ecto.Changeset.t()
  @doc false
  def update_changeset(user, attrs \\ %{}) do
    attrs = update_translations(user, attrs)

    user
    |> cast(attrs, [:name, :email, :translations, :note])
    |> put_lowercase_name()
    |> put_lowercase_email()
    |> validate_required([:name])
    |> validate_format(:name, @name_format)
    |> validate_format(:email, @email_format)
    |> unique_constraint(:name, name: :authors_data_name_index)
    |> unique_constraint(:email, name: :authors_data_email_index)
  end

  @doc false
  @spec delete_changeset(user :: t, attrs :: map) :: Ecto.Changeset.t()
  def delete_changeset(user, attrs \\ %{}) do
    user
    |> update_changeset(attrs)
    |> change(deleted: true)
  end

  defp put_lowercase_name(%Ecto.Changeset{valid?: true, changes: %{name: name}} = changeset)
       when is_binary(name) do
    change(changeset, %{name: name |> String.downcase()})
  end

  defp put_lowercase_name(changeset), do: changeset

  defp put_lowercase_email(%Ecto.Changeset{valid?: true, changes: %{email: email}} = changeset)
       when is_binary(email) do
    email = email |> String.trim() |> String.downcase()

    case email do
      "" ->
        change(changeset, %{email: nil})

      value ->
        change(changeset, %{email: value})
    end
  end

  defp put_lowercase_email(changeset), do: changeset
end
