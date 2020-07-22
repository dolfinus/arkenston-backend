defmodule Arkenston.Subject do
  @moduledoc """
  The Subject context.
  """

  import Ecto.Query, warn: false

  alias Arkenston.Helper.QueryHelper
  alias Arkenston.Repo
  alias Arkenston.Subject.User

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """

  @spec list_users(opts :: QueryHelper.query_opts | list[keyword], context :: QueryHelper.context) :: [User.t]
  def list_users(opts \\ %{}, context \\ %{}) do
    User
    |> QueryHelper.generate_query(opts, context)
    |> Repo.all()
  end

  @doc """
  Gets a single user by search query.

  ## Examples

      iex> get_user_by(id: 123)
      %User{}

      iex> get_user_by(id: 456)
      nil

  """
  @spec get_user_by(opts :: QueryHelper.query_opts | list[keyword], context :: QueryHelper.context) :: User.t|nil
  def get_user_by(opts, context \\ %{}) do
    User
    |> QueryHelper.generate_query(opts, context)
    |> QueryHelper.first()
    |> Repo.one()
  end

  @doc """
  Gets a single user by search query.

  ## Examples

      iex> get_user_by(id: 123)
      %User{}

      iex> get_user_by(id: 456)
      ** (Ecto.NoResultsError)

  """
  @spec get_user_by!(opts :: QueryHelper.query_opts | list[keyword], context :: QueryHelper.context) :: User.t|no_return
  def get_user_by!(opts, context \\ %{}) do
    User
    |> QueryHelper.generate_query(opts, context)
    |> QueryHelper.first()
    |> Repo.one!()
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_user!(id :: User.id, context :: QueryHelper.context) :: User.t|no_return
  def get_user!(id, context \\ %{}), do: get_user_by!(%{id: id}, context)

  @doc """
  Gets a single user by id.

  ## Examples

      iex> get_user(123)
      %User{}

      iex> get_user(456)
      nil

  """
  @spec get_user(id :: User.id, context :: QueryHelper.context) :: User.t|nil
  def get_user(id, context \\ %{}), do: get_user_by(%{id: id}, context)

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_user(attrs :: map, context :: map) :: {:ok, User.t}|{:error, Repo.changeset}
  def create_user(attrs \\ %{}, context \\ %{}) do
    attrs
    |> User.create_changeset()
    |> Repo.audited_insert(context)
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_user(user :: User.t, attrs :: map, context :: map) :: {:ok, User.t}|{:error, Repo.changeset}
  def update_user(%User{} = user, attrs \\ %{}, context \\ %{}) do
    user
    |> User.update_changeset(attrs)
    |> Repo.audited_update(context)
  end

  @doc """
  Deletes a User.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_user(user :: User.t, attrs :: map, context :: map) :: {:ok, User.t}|{:error, Repo.changeset}
  def delete_user(%User{} = user, attrs \\ %{}, context \\ %{}) do
    user
    |> User.delete_changeset(attrs)
    |> Repo.audited_update(context)
  end
end
