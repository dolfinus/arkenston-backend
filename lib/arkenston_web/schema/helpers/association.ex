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

  defmacro connect_with(name, args \\ [])

  defmacro connect_with(name, args) when is_list(args) do
    non_null = args |> Keyword.get(:non_null, false)
    if non_null do
      do_connect_with(name, name, quote(do: non_null(unquote(name))))
    else
      do_connect_with(name, name, name)
    end
  end

  defmacro connect_with(name, type) do
    do_connect_with(name, name, type)
  end

  defmacro connect_with(name, target, type) do
    do_connect_with(name, target, type)
  end

  def do_connect_with(name, target, type) do
    quote do
      field unquote(name), unquote(type) do
        resolve assoc(unquote(target))
      end
    end
  end

  defmacro connect_with_field(target, field, type) do
    do_connect_with_field(target, field, field, type)
  end

  defmacro connect_with_field(target, field, target_field, type) do
    do_connect_with_field(target, field, target_field, type)
  end

  defp do_connect_with_field(target, field, target_field, type) do
    quote do
      field unquote(field), unquote(type) do
        resolve assoc unquote(target), callback: fn result, _parent, _args ->
          {:ok, result |> Map.get(unquote(target_field))}
        end
      end
    end
  end
end
