defmodule ArkenstonWeb.Schema.Helpers.Revision do
  use ArkenstonWeb.Schema.Helpers.Pagination
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
      node object unquote(obj) do
        interface :with_revision
        import_fields :node

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
        connection field :revisions, node_type: unquote(revision_name) do
          paginated(:revisions)
        end
      end

      paginated_node unquote(obj)

      node object unquote(revision_name) do
        interface :revision
        import_fields :revision
        import_fields :node

        unquote(block)
        field unquote(obj), non_null(unquote(obj)) do
          resolve assoc(unquote(obj))
        end
      end

      paginated_node unquote(revision_name)
    end
  end
end
