defmodule Arkenston.Resolver.UserResolver do
  alias Arkenston.Subject
  alias Arkenston.Subject.User

  @spec prepare_fields(module :: any, context :: map) :: list
  def prepare_fields(module, %{fields: fields}) do
    {_fields, result} = fields |> Enum.reduce(fields, fn field, result ->
      case field do
        value when is_atom(value) ->
          {field, result}

        {value, nested} when is_atom(value) ->
          nested_fields = prepare_fields(nested)

          field_id = :"#{value}_id"
          nested_fields = nested_fields ++ case module.__schema__(:fields) |> Enum.member?(field_id) do
            true ->
              [field_id]
            _ ->
              []
          end
          {field, nested_fields}
      end
    end)

    result
  end
  def prepare_fields(_fields), do: []

  @spec all(where :: map, params :: map) :: {:ok, [Arkenston.Subject.User.t()]}
  def all(args \\ %{}, info \\ %{context: %{}})
  def all(where, %{context: context}) when is_map(where) do
    {:ok, Subject.list_users(where, prepare_fields(User, context))}
  end

  def all(_args, %{context: context}) do
    {:ok, Subject.list_users(%{}, prepare_fields(User, context))}
  end

  @spec one(where:: map, params :: map) :: {:error, String.t} | {:ok, User.t} | {:error, any}
  def one(args, info \\ %{context: %{}})
  def one(%{id: id}, %{context: context}) when not is_nil(id) do
    case Subject.get_user(id, prepare_fields(User, context)) do
      nil -> {:error, :not_found}
      user -> {:ok, user}
    end
  end

  def one(where, %{context: context}) when is_map(where) and map_size(where) != 0 do
    case Subject.get_user_by(where, prepare_fields(User, context)) do
      nil -> {:error, :not_found}
      user -> {:ok, user}
    end
  end

  def one(_args, %{context: %{current_user: current_user}} = info) when not is_nil(current_user) do
    one(%{id: current_user.id}, info)
  end

  def one(_args, _info) do
    {:error, :invalid_request}
  end
end
