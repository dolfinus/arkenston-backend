defmodule Arkenston.Subject do
  @moduledoc """
  The Subject context.
  """

  import Ecto.Query, warn: false

  alias Arkenston.Repo
  alias Arkenston.Subject.User

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """

  @spec list_users(opts :: Repo.query_opts, fields :: Repo.fields) :: [%User{}]
  def list_users(opts \\ %{}, fields \\ []) do
    User
    |> generate_query(opts)
    |> Repo.return_fields(fields)
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
  @spec get_user_by(opts :: Repo.query_opts, fields :: Repo.fields) :: %User{}|nil
  def get_user_by(opts \\ %{}, fields \\ []) do
    User
    |> generate_query(opts)
    |> Repo.return_fields(fields)
    |> Repo.first()
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
  @spec get_user_by!(opts :: Repo.query_opts, fields :: Repo.fields) :: %User{}|no_return
  def get_user_by!(opts \\ %{}, fields \\ []) do
    User
    |> generate_query(opts)
    |> Repo.return_fields(fields)
    |> Repo.first()
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
  @spec get_user!(id :: User.id, fields :: Repo.fields) :: %User{}|no_return
  def get_user!(id, fields \\ []), do: get_user_by!(%{id: id}, fields)

  @doc """
  Gets a single user by id.

  ## Examples

      iex> get_user(123)
      %User{}

      iex> get_user(456)
      nil

  """
  @spec get_user(id :: User.id, fields :: Repo.fields) :: %User{}|nil
  def get_user(id, fields \\ []), do: get_user_by(%{id: id}, fields)

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_user(attrs :: map) :: {:ok, any}|{:error, any}
  def create_user(attrs \\ %{}) do
    %User{}
      |> User.create_changeset(attrs)
      |> Repo.audited_insert()
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_user(user :: %User{}, attrs :: map) :: {:ok, any}|{:error, any}
  def update_user(%User{} = user, attrs \\ %{}) do
    user
      |> User.update_changeset(attrs)
      |> Repo.audited_update()
  end

  @doc """
  Deletes a User.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_user(user :: %User{}) :: {:ok, any}|{:error, any}
  def delete_user(%User{} = user) do
    user
      |> User.delete_changeset()
      |> Repo.audited_update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{source: %User{}}

  """
  @spec change_user(user :: %User{}) :: Repo.changeset
  def change_user(%User{} = user) do
    User.update_changeset(user)
  end


  @doc """
  Apply filter for anonymous role

  ## Examples

      iex> filter_anonymous(User)
      {from i in query,
        where: i.role != :anonymous}

      iex> filter_anonymous(query, %{role: :anonymous})
      {from i in query,
        where: i.role == :anonymous, %{}}

      iex> filter_anonymous(User, %{role: :user})
      {from i in query,
        where: i.role == user, %{}}

      iex> filter_anonymous(User, %{some: thing})
      {query, %{some: thing}}

  """
  @spec filter_anonymous(query :: Repo.queryable, opts :: Repo.query_opts) :: {Repo.queryable, Repo.query_opts}
  def filter_anonymous(query, opts \\ %{}) do
    new_query = case opts |> Map.fetch(:role) do
      {:ok, role} when not is_nil(role) and (is_integer(role) or is_atom(role)) ->
        from i in query,
          where: i.role == ^role

      {:ok, _} ->
        query

      :error ->
        from i in query,
          where: i.role != ^:anonymous
    end

    new_opts = cond do
      new_query != query ->
        opts |> Map.delete(:role)
      true ->
        opts
    end

    {new_query, new_opts}
end

  @doc """
  Generate query

  ## Examples

      iex> generate_query(query, %{some: thing}) |> Repo.all
      [
        %Ecto.Subject.User{}
      ]

  """
  @spec generate_query(query :: Repo.queryable) :: Repo.queryable
  def generate_query(query) do
    generate_query(query, %{})
  end

  @spec generate_query(query :: Repo.queryable, opts :: Repo.query_opts) :: Repo.queryable
  def generate_query(query, opts) when is_map(opts) do
    {query, opts} = filter_anonymous(query, opts)
    Repo.generate_query(query, opts)
  end

  @spec generate_query(query :: Repo.queryable, opts :: [keyword]) :: Repo.queryable
  def generate_query(query, opts) when is_list(opts) do
    generate_query(query, opts |> Enum.into(%{}))
  end
end
