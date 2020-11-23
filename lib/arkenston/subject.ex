defmodule Arkenston.Subject do
  @moduledoc """
  The Subject context.
  """

  import Ecto.Query, warn: false

  alias Arkenston.Helper.QueryHelper
  alias Arkenston.Repo
  alias Arkenston.Subject.{User, Author}

  defp filter_user_by_author(query, opts) do
    opts = opts |> Enum.into(%{})

    author_filter = case opts do
      %{name: name, email: email} ->
        QueryHelper.handle_filter(Author, %{name: name, email: email, deleted: nil})
      %{name: name} ->
        QueryHelper.handle_filter(Author, %{name: name, deleted: nil})
      %{email: email} ->
        QueryHelper.handle_filter(Author, %{email: email, deleted: nil})
      _ ->
        nil
    end

    query = case author_filter do
      nil ->
        query
      filter ->
        from u in query,
          join: a in subquery(filter), on: a.id == u.author_id
    end

    opts = opts |> Map.drop([:name, :email])

    {query, opts}
  end

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """

  @spec list_users(opts :: QueryHelper.query_opts | list[keyword], context :: QueryHelper.context) :: [User.t]
  def list_users(opts \\ %{}, context \\ %{}) do
    {query, opts} = filter_user_by_author(User, opts)

    query
    |> QueryHelper.generate_query(opts, context)
    |> Repo.all()
  end

  @doc """
  Returns the list of authors.

  ## Examples

      iex> list_authors()
      [%Author{}, ...]

  """

  @spec list_authors(opts :: QueryHelper.query_opts | list[keyword], context :: QueryHelper.context) :: [Author.t]
  def list_authors(opts \\ %{}, context \\ %{}) do
    Author
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
    {query, opts} = filter_user_by_author(User, opts)

    query
    |> QueryHelper.generate_query(opts, context)
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
  @spec get_author_by(opts :: QueryHelper.query_opts | list[keyword], context :: QueryHelper.context) :: Author.t|nil
  def get_author_by(opts, context \\ %{}) do
    Author
    |> QueryHelper.generate_query(opts, context)
    |> QueryHelper.first()
    |> Repo.one()
  end

  @doc """
  Gets a single user by search query.

  ## Examples

      iex> get_user_by!(id: 123)
      %User{}

      iex> get_user_by!(id: 456)
      ** (Ecto.NoResultsError)

  """
  @spec get_user_by!(opts :: QueryHelper.query_opts | list[keyword], context :: QueryHelper.context) :: User.t|no_return
  def get_user_by!(opts, context \\ %{}) do
    {query, opts} = filter_user_by_author(User, opts)

    query
    |> QueryHelper.generate_query(opts, context)
    |> QueryHelper.first()
    |> Repo.one!()
  end

  @doc """
  Gets a single author by search query.

  ## Examples

      iex> get_author_by!(id: 123)
      %User{}

      iex> get_author_by!(id: 456)
      ** (Ecto.NoResultsError)

  """
  @spec get_author_by!(opts :: QueryHelper.query_opts | list[keyword], context :: QueryHelper.context) :: Author.t|no_return
  def get_author_by!(opts, context \\ %{}) do
    Author
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
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_author!(id :: User.id, context :: QueryHelper.context) :: Author.t|no_return
  def get_author!(id, context \\ %{}), do: get_author_by!(%{id: id}, context)

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
  Gets a single author by id.

  ## Examples

      iex> get_author(123)
      %Author{}

      iex> get_author(456)
      nil

  """
  @spec get_author(id :: Author.id, context :: QueryHelper.context) :: Author.t|nil
  def get_author(id, context \\ %{}), do: get_author_by(%{id: id}, context)

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
  Creates an author.

  ## Examples

      iex> create_author(%{field: value})
      {:ok, %Author{}}

      iex> create_author(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_author(attrs :: map, context :: map) :: {:ok, Author.t}|{:error, Repo.changeset}
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
  @spec update_user(user :: User.t, attrs :: map, context :: map) :: {:ok, User.t}|{:error, Repo.changeset}
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
  @spec update_author(author :: Author.t, attrs :: map, context :: map) :: {:ok, Author.t}|{:error, Repo.changeset}
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
  @spec delete_user(user :: User.t, attrs :: map, context :: map) :: {:ok, User.t}|{:error, Repo.changeset}
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
  @spec delete_author(author :: Author.t, attrs :: map, context :: map) :: {:ok, Author.t}|{:error, Repo.changeset}
  def delete_author(%Author{} = author, attrs \\ %{}, context \\ %{}) do
    author
    |> Author.delete_changeset(attrs)
    |> Repo.audited_update(context)
  end
end
