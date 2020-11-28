defmodule ArkenstonWeb.Schema.Helpers.Pagination do
  alias Arkenston.Helper.QueryHelper
  use ArkenstonWeb.Schema.Helpers.Association

  @default_page_size Application.compile_env(:arkenston, [ArkenstonWeb.Endpoint, :page_size])

  defmacro __using__(_opts) do
    current = __MODULE__

    quote do
      import unquote(current)
    end
  end

  defmacro paginated(name) when is_atom(name) do
    quote do
      arg :first, :page_size
      arg :last, :page_size

      resolve assoc unquote(name),
                callback: fn result, _parent, args ->
                  QueryHelper.paginate_slice(result, args)
                end
    end
  end

  defmacro paginated(resolver) do
    quote do
      arg :first, :page_size
      arg :last, :page_size

      resolve fn
        args, context ->
          {:ok, result} = unquote(resolver).(args, context)

          QueryHelper.paginate_slice(result, args)
      end
    end
  end

  defmacro paginated_node(type) do
    quote do
      connection node_type: unquote(type) do
        edge do
          field :node, unquote(type) do
            complexity fn args, child_complexity ->
              first = args |> Map.get(:first, unquote(@default_page_size))
              last = args |> Map.get(:last, unquote(@default_page_size))

              min(first, last) * child_complexity
            end
          end
        end
      end
    end
  end
end
