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
        defaults = unquote(args) |> Keyword.get(:defaults, %{})
        args = unquote(args) |> Keyword.drop([:defaults])

        case parent |> Map.get(unquote(name)) do
          %Ecto.Association.NotLoaded{} ->
            dataloader(
              Arkenston.Repo,
              unquote(name),
              args ++ [use_parent: true, args: %{context: resolution.context}]
            ).(parent, defaults |> Map.merge(opts), resolution)

          loaded ->
            {:ok, loaded}
        end
      end
    end
  end

  defmacro connect_with_audited(name, args \\ [])

  defmacro connect_with_audited(name, args) when is_list(args) do
    non_null = args |> Keyword.get(:non_null, false)
    args = args |> Keyword.drop([:non_null])

    if non_null do
      do_connect_with_audited(name, name, quote(do: non_null(unquote(name))), args, do: [])
    else
      do_connect_with_audited(name, name, name, args, do: [])
    end
  end

  defmacro connect_with_audited(name, type) do
    do_connect_with_audited(name, name, type, [], do: [])
  end

  defmacro connect_with_audited(name, target, type) do
    do_connect_with_audited(name, target, type, [], do: [])
  end

  defmacro connect_with_audited(name, target, type, args) do
    do_connect_with_audited(name, target, type, args, do: [])
  end

  defmacro connect_with_audited(name, target, type, args, do: block) do
    do_connect_with_audited(name, target, type, args, do: block)
  end

  defp do_connect_with_audited(name, target, type, args, do: block) do
    quote do
      connect_with unquote(name), unquote(target), unquote(type), unquote(args) do
        arg :deleted, :boolean
        unquote(block)
      end
    end
  end

  defmacro connect_with(name, args \\ [])

  defmacro connect_with(name, args) when is_list(args) do
    non_null = args |> Keyword.get(:non_null, false)
    args = args |> Keyword.drop([:non_null])

    if non_null do
      do_connect_with(name, name, quote(do: non_null(unquote(name))), args, do: [])
    else
      do_connect_with(name, name, name, args, do: [])
    end
  end

  defmacro connect_with(name, type) do
    do_connect_with(name, name, type, [], do: [])
  end

  defmacro connect_with(name, target, type) do
    do_connect_with(name, target, type, [], do: [])
  end

  defmacro connect_with(name, target, type, args) do
    do_connect_with(name, target, type, args, do: [])
  end

  defmacro connect_with(name, target, type, args, do: block) do
    do_connect_with(name, target, type, args, do: block)
  end

  defp do_connect_with(name, target, type, args, do: block) do
    quote do
      field unquote(name), unquote(type) do
        unquote(block)
        resolve assoc(unquote(target), unquote(args))
      end
    end
  end

  defmacro connect_with_field_audited(target, field, type) do
    do_connect_with_field_audited(target, field, field, type, [], do: [])
  end

  defmacro connect_with_field_audited(target, field, target_field, type) do
    do_connect_with_field_audited(target, field, target_field, type, [], do: [])
  end

  defmacro connect_with_field_audited(target, field, target_field, type, args) do
    do_connect_with_field_audited(target, field, target_field, type, args, do: [])
  end

  defp do_connect_with_field_audited(target, field, target_field, type, args, do: block) do
    quote do
      connect_with_field unquote(target),
                         unquote(field),
                         unquote(target_field),
                         unquote(type),
                         unquote(args) ++ [defaults: %{deleted: nil}] do
        unquote(block)
      end
    end
  end

  defmacro connect_with_field(target, field, type) do
    do_connect_with_field(target, field, field, type, [], do: [])
  end

  defmacro connect_with_field(target, field, target_field, type) do
    do_connect_with_field(target, field, target_field, type, [], do: [])
  end

  defmacro connect_with_field(target, field, target_field, type, args) do
    do_connect_with_field(target, field, target_field, type, args, do: [])
  end

  defmacro connect_with_field(target, field, target_field, type, args, do: block) do
    do_connect_with_field(target, field, target_field, type, args, do: block)
  end

  defp do_connect_with_field(target, field, target_field, type, args, do: block) do
    quote do
      field unquote(field), unquote(type) do
        unquote(block)

        resolve assoc(
                  unquote(target),
                  unquote(args) ++
                    [
                      callback: fn result, _parent, _args ->
                        {:ok, result |> Map.get(unquote(target_field))}
                      end
                    ]
                )
      end
    end
  end
end
