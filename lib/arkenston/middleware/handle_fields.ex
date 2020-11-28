defmodule Arkenston.Middleware.HandleFields do
  @moduledoc false

  @behaviour Absinthe.Middleware

  @type resolution() :: Absinthe.Resolution.t()
  @type field() :: Absinthe.Blueprint.Document.Field.t() | Absinthe.Blueprint.Document.Fragment.Spread.t()

  @spec call(resolution(), any()) :: resolution()
  def call(%{context: context} = resolution, _config) do
    fields =
      resolution
      |> Absinthe.Resolution.project()
      |> Enum.map(&handle_field/1)

    %{resolution | context: Map.put(context, :fields, fields)}
  end

  @spec handle_field(field() | map()) :: atom() | {atom(), map() | list()}
  def handle_field(%{name: name, selections: []}) do
    handle_field(%{name: name})
  end

  def handle_field(%{name: name, selections: %{} = selections}) when map_size(selections) == 0 do
    handle_field(%{name: name})
  end

  def handle_field(%{name: name, selections: selections})
      when is_list(selections) or is_map(selections) do
    {handle_field(%{name: name}), Enum.map(selections, &handle_field/1)}
  end

  def handle_field(%{name: name}) when is_atom(name) do
    name
  end

  def handle_field(%{name: name}) do
    :"#{name}"
  end
end
