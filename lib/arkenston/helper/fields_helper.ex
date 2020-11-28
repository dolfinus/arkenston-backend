defmodule Arkenston.Helper.FieldsHelper do
  import Ecto.Query, warn: false

  alias Arkenston.Helper.QueryHelper

  @id_name Application.compile_env(:arkenston, [Arkenston.Repo, :migration_primary_key, :name])

  @type fields :: [atom | {atom, fields}]
  @type fields_context :: %{fields: fields}

  @spec prepare_fields(module :: atom, context :: fields_context) :: fields
  def prepare_fields(%Ecto.Query{from: %Ecto.Query.FromExpr{source: {_table, module}}}, context) do
    prepare_fields(module, context)
  end

  def prepare_fields(module, %{fields: fields}) when is_atom(module) do
    Enum.reduce(fields, module.__schema__(:primary_key), fn field, result ->
      case field do
        value when is_atom(value) or is_binary(value) ->
          field =
            field
            |> to_string()
            |> Macro.underscore()
            |> String.to_existing_atom()

          new_fields =
            try do
              [field, "#{field}_#{@id_name}" |> String.to_existing_atom()]
            rescue
              _ ->
                [field]
            end

          new_fields =
            if Keyword.has_key?(module.__info__(:functions), :__trans__) and
                 Trans.translatable?(module, field) do
              new_fields ++ [:translations]
            else
              new_fields
            end

          new_fields =
            new_fields
            |> Enum.filter(fn name ->
              module.__schema__(:fields) |> Enum.member?(name)
            end)

          result ++ new_fields

        {value, nested} when is_atom(value) ->
          result ++
            prepare_fields(module, %{fields: [value]}) ++
            prepare_fields(module, %{fields: nested})
      end
    end)
    |> Enum.uniq()
  end

  def prepare_fields(_module, _fields), do: []

  @doc """
  Limit return fields list in SELECT query

  ## Examples

      iex> return_fields(query, [:id, :name])
      from i in query,
        select: [:id, :name]

  """
  @spec return_fields(query :: QueryHelper.queryable(), fields :: fields) ::
          QueryHelper.queryable()
  def return_fields(query, fields) when is_list(fields) and length(fields) != 0 do
    query
    |> select(^fields)
  end

  def return_fields(query, _fields) do
    query
  end
end
