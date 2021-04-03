defmodule ArkenstonWeb.Schema.Types.Custom.UUID6 do
  @moduledoc """
  The UUID6 scalar type allows UUID6 compliant strings to be passed in and out.
  Requires `{ :ecto, ">= 0.0.0" }` package: https://github.com/elixir-ecto/ecto
  """
  use Absinthe.Schema.Notation

  alias Ecto.UUID

  scalar :uuid6, name: "UUID6" do
    description """
      The `UUID6` scalar type represents UUID6 compliant string data, represented as UTF-8
      character sequences. The UUID6 type is most often used to represent unique
      human-readable ID strings.
    """

    serialize(&encode/1)
    parse(&decode/1)
  end

  @spec decode(Absinthe.Blueprint.Input.String.t()) :: {:ok, term()} | :error
  @spec decode(Absinthe.Blueprint.Input.Null.t()) :: {:ok, nil}
  defp decode(%Absinthe.Blueprint.Input.String{value: value}) do
    UUID.cast(value)
  end

  defp decode(%Absinthe.Blueprint.Input.Null{}) do
    {:ok, nil}
  end

  defp decode(_) do
    :error
  end

  defp encode(value), do: value
end
