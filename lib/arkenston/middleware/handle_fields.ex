defmodule Arkenston.Middleware.HandleFields do
  @moduledoc false

  @behaviour Absinthe.Middleware

  alias Absinthe.Resolution
  alias Absinthe.Blueprint.Document.Field

  @type resolution() :: Absinthe.Resolution.t()
  @type field() :: Absinthe.Blueprint.Document.Field.t()

  @spec call(resolution(), any()) :: resolution()
  def call(resolution, config)

  def call(%{context: context} = resolution, _config) do
    fields =
      resolution
      |> Resolution.project()
      |> Enum.map(&field/1)
      |> Enum.map(&String.to_atom/1)

    %{resolution | context: Map.put(context, :fields, fields)}
  end

  @spec field(field()) :: binary() | map()
  def field(%Field{name: name, selections: []}), do: name

  def field(%Field{name: name, selections: selections}),
    do: %{name => Enum.map(selections, &field/1)}

  def field(%Field{name: name}), do: name
end
