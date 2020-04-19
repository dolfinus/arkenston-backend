defmodule ArkenstonWeb.Schema.Types.AuditedObject do
  defmacro __using__(_opts) do
    current = __MODULE__

    quote do
      import unquote(current)
      import Absinthe.Resolution.Helpers, only: [dataloader: 1]
    end
  end

  defmacro audited_object(obj, [do: block]) when is_atom(obj) do
    orig_name = obj |> Atom.to_string()
    revision_name = "#{orig_name}_revision" |> String.to_atom()

    quote do
      object unquote(obj) do
        interface :with_revision

        unquote(block)
        field :first_revision,  non_null(unquote(revision_name)), resolve: dataloader(Arkenston.Repo)
        field :latest_revision, non_null(unquote(revision_name)), resolve: dataloader(Arkenston.Repo)
        field :revisions,       non_null(list_of(unquote(revision_name))), resolve: dataloader(Arkenston.Repo)
      end

      object unquote(revision_name) do
        interface :revision

        unquote(block)
        field unquote(obj), non_null(unquote(obj)), resolve: dataloader(Arkenston.Repo)
        import_fields :revision
      end
    end
  end
end
