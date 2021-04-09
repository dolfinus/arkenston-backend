defmodule Arkenston.Subject do
  @moduledoc """
  The Subject context.
  """

  import Ecto.Query, warn: false

  alias Arkenston.Helper.QueryHelper
  alias Arkenston.Repo
  alias Arkenston.Subject.{User, Author}

  defp filter_author(query, opts) do
    opts = opts |> Enum.into(%{})

    new_query =
      case opts do
        %{name: name, email: email} ->
          QueryHelper.handle_filter(
            query,
            opts |> Map.merge(%{name: {:lower, name}, email: {:lower, email}})
          )

        %{name: name} ->
          QueryHelper.handle_filter(query, opts |> Map.merge(%{name: {:lower, name}}))

        %{email: email} ->
          QueryHelper.handle_filter(query, opts |> Map.merge(%{email: {:lower, email}}))

        _ ->
          query
      end

    new_opts = opts |> Map.drop([:name, :email])

    {new_query, new_opts}
  end

  defp filter_user_by_author(query, opts) do
    opts = opts |> Enum.into(%{})

    {author_filter, _} =
      filter_author(Author, opts |> Map.take([:name, :email]) |> Map.put(:deleted, nil))

    new_query =
      case author_filter do
        value when is_atom(value) ->
          query

        filter ->
          filter =
            from a in filter,
              select: a.id

          from u in query, join: a in subquery(filter), on: a.id == u.author_id
      end

    new_opts = opts |> Map.drop([:name, :email])

    {new_query, new_opts}
  end

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """

  @spec list_users(opts :: QueryHelper.query_opts() | list[keyword]) :: [User.t()]
  def list_users(opts \\ %{}) do
    {query, opts} = filter_user_by_author(User, opts)

    query
    |> QueryHelper.generate_query(opts)
    |> Repo.all()
  end

  @doc """
  Returns the list of authors.

  ## Examples

      iex> list_authors()
      [%Author{}, ...]

  """

  @spec list_authors(opts :: QueryHelper.query_opts() | list[keyword]) :: [Author.t()]
  def list_authors(opts \\ %{}) do
    {query, opts} = filter_author(Author, opts)

    query
    |> QueryHelper.generate_query(opts)
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
  @spec get_user_by(opts :: QueryHelper.query_opts() | list[keyword]) :: User.t() | nil
  def get_user_by(opts) do
    {query, opts} = filter_user_by_author(User, opts)

    query
    |> QueryHelper.generate_query(opts)
    |> QueryHelper.first()
    |> Repo.one()
  end

  @doc """
  Gets a single author by search query.

  ## Examples

      iex> get_author_by(id: 123)
      %Author{}

      iex> get_author_by(id: 456)
      nil

  """
  @spec get_author_by(opts :: QueryHelper.query_opts() | list[keyword]) :: Author.t() | nil
  def get_author_by(opts) do
    {query, opts} = filter_author(Author, opts)

    query
    |> QueryHelper.generate_query(opts)
    |> QueryHelper.first()
    |> Repo.one()
  end

  @doc """
  Gets a single user by id.

  ## Examples

      iex> get_user(123)
      %User{}

      iex> get_user(456)
      nil

  """
  @spec get_user(id :: User.id()) :: User.t() | nil
  def get_user(id), do: get_user_by(%{id: id})

  @doc """
  Gets a single author by id.

  ## Examples

      iex> get_author(123)
      %Author{}

      iex> get_author(456)
      nil

  """
  @spec get_author(id :: Author.id()) :: Author.t() | nil
  def get_author(id), do: get_author_by(%{id: id})

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_user(attrs :: map, context :: map) :: {:ok, User.t()} | {:error, Repo.changeset()}
  def create_user(attrs \\ %{}, context \\ %{}) do
    attrs
    |> User.create_changeset()
    |> Repo.audited_insert(context)
  end

  @doc """
  Creates an author.

  ## Examples

      iex> create_author(%{field: value})
      {:ok, %Author{}}

      iex> create_author(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_author(attrs :: map, context :: map) ::
          {:ok, Author.t()} | {:error, Repo.changeset()}
  def create_author(attrs \\ %{}, context \\ %{}) do
    attrs
    |> Author.create_changeset()
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
  @spec update_user(user :: User.t(), attrs :: map, context :: map) ::
          {:ok, User.t()} | {:error, Repo.changeset()}
  def update_user(%User{} = user, attrs \\ %{}, context \\ %{}) do
    user
    |> User.update_changeset(attrs)
    |> Repo.audited_update(context)
  end

  @doc """
  Updates an author.

  ## Examples

      iex> update_author(user, %{field: new_value})
      {:ok, %Author{}}

      iex> update_author(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_author(author :: Author.t(), attrs :: map, context :: map) ::
          {:ok, Author.t()} | {:error, Repo.changeset()}
  def update_author(%Author{} = author, attrs \\ %{}, context \\ %{}) do
    author
    |> Author.update_changeset(attrs)
    |> Repo.audited_update(context)
  end

  @doc """
  Deletes a user.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_user(user :: User.t(), attrs :: map, context :: map) ::
          {:ok, User.t()} | {:error, Repo.changeset()}
  def delete_user(%User{} = user, attrs \\ %{}, context \\ %{}) do
    user
    |> User.delete_changeset(attrs)
    |> Repo.audited_update(context)
  end

  @doc """
  Deletes an author.

  ## Examples

      iex> delete_author(author)
      {:ok, %Author{}}

      iex> delete_author(author)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_author(author :: Author.t(), attrs :: map, context :: map) ::
          {:ok, Author.t()} | {:error, Repo.changeset()}
  def delete_author(%Author{} = author, attrs \\ %{}, context \\ %{}) do
    author
    |> Author.delete_changeset(attrs)
    |> Repo.audited_update(context)
  end
end
