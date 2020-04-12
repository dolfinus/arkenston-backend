defmodule ArkenstonWeb.Schema.Types.Interface.WithRevision do
  use Absinthe.Schema.Notation

  interface :with_revision do
    field :first_revision,  non_null(:revision)
    field :latest_revision, non_null(:revision)
    field :revisions,       non_null(list_of(:revision))

    resolve_type fn
      %{id: id}, %{context: context} ->
        case Arkenston.Subject.UserResolver.one(%{id: id}, %{context: context}) do
          {:ok, _} ->
            :user
          {:error, _} ->
            nil
        end
      _, _ -> nil
    end
  end
end
