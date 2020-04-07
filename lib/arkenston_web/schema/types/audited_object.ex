defmodule ArkenstonWeb.Schema.Types.AuditedObject do
  defmacro __using__(_opts) do
    current = __MODULE__

    quote do
      import unquote(current)

      interface :revision do
        field :version,    non_null(:integer)
        field :created_by, non_null(:user)
        field :created_at, non_null(:datetime)

        resolve_type fn
          _, _ -> nil
        end
      end

      interface :with_revision do
        field :first_revision,  non_null(:revision)
        field :latest_revision, non_null(:revision)
        field :revisions,       non_null(list_of(:revision))

        resolve_type fn
          %{id: id}, %{context: context} ->
            case Arkenston.Subject.UserResolver.find(%{id: id}, %{context: context}) do
              {:ok, _} ->
                :user
              {:error, _} ->
                nil
            end
          _, _ -> nil
        end
      end
    end
  end

  defmacro audited_object(obj, [do: block]) when is_atom(obj) do
    orig_name = obj |> Atom.to_string()
    audit_name = "#{orig_name}_revision" |> String.to_atom()

    quote do
      object unquote(obj) do
        interface :with_revision

        unquote(block)
        field :first_revision,  non_null(unquote(audit_name))
        field :latest_revision, non_null(unquote(audit_name))
        field :revisions,       non_null(list_of(unquote(audit_name)))
      end

      object unquote(audit_name) do
        interface :revision

        unquote(block)
        field :version,    non_null(:integer)
        field :created_by, non_null(:user)
        field :created_at, non_null(:datetime)
      end
    end
  end
end
