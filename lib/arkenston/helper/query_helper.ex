defmodule Arkenston.Helper.QueryHelper do
  import Ecto.Query, warn: false

  alias Arkenston.Helper.FieldsHelper
  alias Absinthe.Relay.Connection

  @type query :: Ecto.Query.t()
  @type queryable :: Ecto.Queryable.t() | module
  @type context :: map
  @type limit :: pos_integer
  @type offset :: pos_integer
  @type first :: pos_integer
  @type last :: pos_integer
  @type count :: pos_integer
  @type order :: :desc | :asc

  @type filter_arg :: atom | number | String.t() | map
  @type filter_opt :: %{optional(atom) => filter_arg | {atom, filter_arg}}
  @type deleted_opt :: %{deleted: boolean | nil}
  @type order_opt :: %{order: keyword(order) | %{optional(atom) => order}}
  @type pagination_opt :: %{
          optional(:first) => first,
          optional(:last) => last,
          optional(:count) => count
        }
  @type fields_opt :: %{fields: FieldsHelper.fields()}
  @type query_opts :: filter_opt | deleted_opt | order_opt | pagination_opt | fields_opt

  @default_page_size Application.compile_env(:arkenston, [ArkenstonWeb.Endpoint, :page_size])
  @max_page_size Application.compile_env(:arkenston, [ArkenstonWeb.Endpoint, :max_page_size])
  @reserved_field_names [:order, :first, :last, :count, :before, :after]

  @doc """
  Apply filter for 'deleted' column

  ## Examples

      iex> filter_deleted(query, %{deleted: true, some: thing})
      {from i in query,
        where: i.deleted == true, %{some: thing}}

      iex> filter_deleted(User)
      {from i in query,
        where: i.deleted == false}

      iex> filter_deleted(User, %{deleted: false, some: thing})
      {from i in query,
        where: i.deleted == false, %{some: thing}}

      iex> filter_deleted(User, %{deleted: nil, some: thing})
      {query, %{some: thing}}

  """
  @spec filter_deleted(query :: queryable, opts :: query_opts) :: {queryable, query_opts}
  def filter_deleted(query, opts \\ %{}) do
    new_query =
      case opts |> Map.fetch(:deleted) do
        {:ok, deleted} when not is_nil(deleted) ->
          from i in query,
            where: i.deleted == ^deleted

        {:ok, nil} ->
          query

        :error ->
          from i in query,
            where: i.deleted == false
      end

    new_opts = opts |> Map.delete(:deleted)

    {new_query, new_opts}
  end

  @doc """
  Return first query result

  ## Examples

      iex> first(query)
      from i in query,
        where: limit == 1

  """
  @spec first(query :: queryable) :: queryable
  def first(query) do
    from i in query,
      limit: 1
  end

  @doc """
  Add WHERE clause to SELECT query

  ## Examples

      iex> handle_filter(query)
      {query, %{}}

      iex> handle_filter(User, %{some: thing, limit: 1})
      {from i in query,
        where: i.some == thing, %{limit: 1}}

  """
  @spec handle_filter(query :: queryable, opts :: query_opts) :: queryable
  def handle_filter(query, opts \\ %{}) do
    {query, opts} = filter_deleted(query, opts)
    options = opts |> Enum.to_list()

    options
    |> Enum.reduce(query, fn option, query ->
      case option do
        {key, {:lower, value}} ->
          from i in query,
            where: fragment("lower(?)", field(i, ^key)) == fragment("lower(?)", ^value)

        {key, value} when is_nil(value) ->
          from i in query,
            where: is_nil(field(i, ^key))

        {key, value} ->
          from i in query,
            where: field(i, ^key) == ^value

        _ ->
          query
      end
    end)
  end

  @doc """
  Add result order handler

  ## Examples

      iex> handle_order(query)
      query

      iex> handle_order(User, %{order: [column: :desc]})
      from i in query,
        order: ^[column: :desc]

  """
  @spec handle_order(query :: queryable, opts :: query_opts) :: queryable
  def handle_order(query, opts \\ %{}) do
    case opts do
      %{order: order} ->
        from i in query, order_by: ^order

      _ ->
        query
    end
  end

  @doc """
  Add pagination case handler

  ## Examples

      iex> get_offset_limit()
      {:ok, #{@max_page_size}, #{@default_page_size}}

      iex> get_offset_limit(%{first: 2})
      {:ok, #{@max_page_size}, 2}

      iex> get_offset_limit(%{last: 2, count: 5})
      {:ok, 5-2, 2}

      iex> get_offset_limit(%{last: 2})
      {:error, _}

  """
  @spec get_offset_limit(opts :: query_opts) :: {:ok, offset, limit} | {:error, String.t()}
  def get_offset_limit(opts \\ %{}) do
    opts =
      if not Map.has_key?(opts, :first) and not Map.has_key?(opts, :last) do
        opts |> Map.put(:first, @default_page_size)
      else
        opts
      end

    with {:ok, _offset, _limit} = result <-
           Connection.offset_and_limit_for_query(opts,
             count: Map.get(opts, :count),
             max: @max_page_size
           ) do
      result
    end
  end

  @doc """
  Add pagination case handler

  ## Examples

      iex> handle_pagination(query)
      query

      iex> handle_pagination(User, %{first: 2})
      from i in query,
        limit: ^40,
        offset: ^20

      iex> handle_pagination(User, %{first: 10, after: "YXJyYXljb25uZWN0aW9uOjA="})
      from i in query,
        limit: ^10,
        offset: ^1

      iex> handle_pagination(User, %{last: 1, before: "YXJyYXljb25uZWN0aW9uOjE="})
      from i in query,
        limit: ^1,
        offset: ^(2-1)

  """
  @spec handle_pagination(query :: queryable, opts :: query_opts) :: queryable
  def handle_pagination(query, opts \\ %{}) do
    with {:ok, offset, limit} <- get_offset_limit(opts) do
      query
      |> limit(^(limit + 1))
      |> offset(^offset)
    end
  end

  @doc """
  Add pagination case handler

  ## Examples

      iex> paginate_slice(User, %{first: 2})
      from i in query,
        limit: ^40,
        offset: ^20

      iex> paginate_slice(User, %{first: 10, after: "YXJyYXljb25uZWN0aW9uOjA="})
      from i in query,
        limit: ^10,
        offset: ^1

      iex> paginate_slice(User, %{last: 1, before: "YXJyYXljb25uZWN0aW9uOjE="})
      from i in query,
        limit: ^1,
        offset: ^(2-1)

  """
  @spec paginate_slice(records :: list, opts :: query_opts) :: queryable
  def paginate_slice(records, opts \\ %{}) do
    with {:ok, offset, limit} <- get_offset_limit(opts) do
      args = [
        has_previous_page: offset > 0,
        has_next_page: length(records) > limit,
        max: @max_page_size
      ]

      Connection.from_slice(Enum.take(records, limit), offset, args)
    end
  end

  @doc """
  Add WHERE clause to SELECT query

  ## Examples

      iex> generate_query(query)
      query

      iex> generate_query(User, %{some: thing, first: 1, order: %{colum: desc}})
      from i in query,
        where: i.some == thing,
        limit: 1,
        order_by: [desc: column]

  """
  @spec generate_query(query :: queryable, opts :: query_opts | list, context :: context) ::
          queryable
  def generate_query(query, opts \\ %{}, context \\ %{})

  def generate_query(query, opts, context) when is_list(opts) do
    generate_query(query, opts |> Enum.into(%{}), context)
  end

  def generate_query(query, %{context: ctx} = opts, _context) when is_map(ctx) do
    generate_query(query, opts |> Map.drop([:context]), ctx)
  end

  def generate_query(query, opts, context) do
    opts =
      case opts do
        %{fields: fields} ->
          fields_map = fields |> Enum.into(%{})
          opts |> Map.drop([:fields]) |> Map.merge(fields_map)

        _ ->
          opts
      end

    filter_opts = Map.drop(opts, @reserved_field_names)
    fields = query |> FieldsHelper.prepare_fields(context)

    query
    |> handle_order(opts)
    |> handle_pagination(opts)
    |> handle_filter(filter_opts)
    |> FieldsHelper.return_fields(fields)
  end
end
