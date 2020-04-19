defmodule Arkenston.Helper.FieldsHelper do
  import Ecto.Query, warn: false

  alias Arkenston.Helper.QueryHelper

  @type fields :: [atom|{atom, fields}]
  @type fields_context :: %{fields: fields}

  @spec prepare_fields(module :: atom, context :: fields_context) :: fields
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

  @doc """
  Limit return fields list in SELECT query

  ## Examples

      iex> return_fields(query, [:id, :name])
      from i in query,
        select: [:id, :name]

  """
  @spec return_fields(query :: QueryHelper.queryable, fields :: fields) :: QueryHelper.queryable
  def return_fields(query, fields) when is_list(fields) and length(fields) != 0 do
    query
    |> select(^fields)
  end

  def return_fields(query, _fields) do
    query
  end
end
