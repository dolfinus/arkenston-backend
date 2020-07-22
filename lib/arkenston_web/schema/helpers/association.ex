defmodule ArkenstonWeb.Schema.Helpers.Association do
  import Absinthe.Resolution.Helpers, only: [dataloader: 3]

  defmacro __using__(_opts) do
    current = __MODULE__

    quote do
      import unquote(current)
    end
  end

  defmacro assoc(name, args \\ []) do
    quote do
      fn parent, opts, resolution ->
        case parent |> Map.get(unquote(name)) do
          %Ecto.Association.NotLoaded{} ->
            dataloader(Arkenston.Repo, unquote(name), unquote(args) ++ [use_parent: true, args: %{context: resolution.context}]).(parent, opts, resolution)
          loaded ->
            {:ok, loaded}
        end
      end
    end
  end
end
