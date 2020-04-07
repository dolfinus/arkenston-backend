defmodule Arkenston.Middleware.HandleFields do
  @moduledoc false

  @behaviour Absinthe.Middleware

  alias Absinthe.Resolution

  @type resolution() :: Absinthe.Resolution.t()
  @type field() :: Absinthe.Blueprint.Document.Field.t() | Absinthe.Blueprint.Document.Fragment.Spread.t()

  @spec call(resolution(), any()) :: resolution()
  def call(resolution, config)

  def call(%{context: context} = resolution, _config) do
    fields =
      resolution
      |> Resolution.project()
      |> Enum.map(&field/1)

    %{resolution | context: Map.put(context, :fields, fields)}
  end

  @spec field(field()) :: binary() | map()
  def field(%{name: name, selections: selections}) when (is_list(selections) or is_map(selections)) and length(selections) == 0 do
    name |> String.to_atom()
  end

  def field(%{name: name, selections: selections}) when is_list(selections) or is_map(selections) do
    {String.to_atom(name), Enum.map(selections, &field/1)}
  end

  def field(%{name: name}) when is_binary(name) do
    name |> String.to_atom()
  end

  def field(%{name: name}) do
    name
  end
end
