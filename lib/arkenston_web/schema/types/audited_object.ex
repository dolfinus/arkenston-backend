defmodule ArkenstonWeb.Schema.Types.AuditedObject do
  use ArkenstonWeb.Schema.Helpers.Association
  defmacro __using__(_opts) do
    current = __MODULE__

    quote do
      import unquote(current)
    end
  end

  defmacro audited_object(obj, [do: block]) when is_atom(obj) do
    orig_name = obj |> Atom.to_string()
    revision_name = "#{orig_name}_revision" |> String.to_atom()

    quote do
      object unquote(obj) do
        interface :with_revision

        unquote(block)
        field :version,    non_null(:integer)
        field :created_at, non_null(:datetime)
        field :updated_at, :datetime
        field :note,       :string
        field :created_by, :user do
          resolve assoc(:created_by)
        end
        field :updated_by, :user do
          resolve assoc(:updated_by)
        end
        field :revisions,  non_null(list_of(non_null(unquote(revision_name)))) do
          resolve assoc(:revisions)
        end
      end

      object unquote(revision_name) do
        interface :revision

        unquote(block)
        field unquote(obj), non_null(unquote(obj)) do
          resolve assoc(unquote(obj))
        end
        import_fields :revision
      end
    end
  end
end
