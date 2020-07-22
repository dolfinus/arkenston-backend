defmodule ArkenstonWeb.Schema.Types.Custom.PageSize do
  use Absinthe.Schema.Notation

  @max_page_size Application.get_env(:arkenston, ArkenstonWeb.Endpoint)[:max_page_size]

  @desc "Integer which value should be between 1 and #{@max_page_size}"
  scalar :page_size, name: "PageSize" do
    serialize(&encode/1)
    parse(&decode/1)
  end

  @spec decode(Absinthe.Blueprint.Input.Integer.t()) :: {:ok, term()} | :error
  @spec decode(Absinthe.Blueprint.Input.Null.t()) :: {:ok, nil}
  defp decode(%Absinthe.Blueprint.Input.Integer{value: value}) do
    if value > 0 and value <= @max_page_size do
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
