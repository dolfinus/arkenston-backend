defmodule Arkenston.Helper.StructHelper do
  defmacro __using__(_opts \\ []) do
    quote do
      defimpl Enumerable do
        alias Enumerable, as: E
        def count(struct), do: Map.from_struct(struct) |> E.count()
        def member?(struct, key), do: Map.from_struct(struct) |> E.member?(key)
        def reduce(struct, acc, fun), do: Map.from_struct(struct) |> E.reduce(acc, fun)
        def slice(struct), do: Map.from_struct(struct) |> E.slice()
      end

      defdelegate fetch(struct, key), to: Map
      defdelegate get(struct, key), to: Map
      defdelegate get(struct, key, default), to: Map
      defdelegate get_and_update(struct, key, value), to: Map
    end
  end
end
