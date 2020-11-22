defmodule ArkenstonWeb.Schema.Types.Custom.PositiveInteger do
  use Absinthe.Schema.Notation

  scalar :positive_integer, name: "PositiveInt" do
    description """
      Integer which value should be strictly above zero
    """

    serialize(&encode/1)
    parse(&decode/1)
  end

  @spec decode(Absinthe.Blueprint.Input.Integer.t()) :: {:ok, pos_integer} | :error
  @spec decode(Absinthe.Blueprint.Input.Null.t()) :: {:ok, nil}
  defp decode(%Absinthe.Blueprint.Input.Integer{value: value}) do
    if value > 0 do
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
