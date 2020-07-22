defmodule ArkenstonWeb.Schema.Types.Custom.NonNegativeInteger do
  use Absinthe.Schema.Notation

  scalar :non_negative_integer, name: "NonNegativeInt" do
    description """
      Integer which value should not be below zero
    """

    serialize(&encode/1)
    parse(&decode/1)
  end

  @spec decode(Absinthe.Blueprint.Input.Integer.t()) :: {:ok, term()} | :error
  @spec decode(Absinthe.Blueprint.Input.Null.t()) :: {:ok, nil}
  defp decode(%Absinthe.Blueprint.Input.Integer{value: value}) do
    if value >= 0 do
      {:ok, value}
    else
      :error
    end
  end

  defp decode(%Absinthe.Blueprint.Input.Null{}) do
    {:ok, nil}
  end

  defp decode(_) do
    :error
  end

  defp encode(value), do: value
end
