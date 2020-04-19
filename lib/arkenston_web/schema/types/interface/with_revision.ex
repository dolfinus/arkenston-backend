defmodule ArkenstonWeb.Schema.Types.Interface.WithRevision do
  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  interface :with_revision do
    field :first_revision,  non_null(:revision), resolve: dataloader(Arkenston.Repo)
    field :latest_revision, non_null(:revision), resolve: dataloader(Arkenston.Repo)
    field :revisions,       non_null(list_of(:revision)), resolve: dataloader(Arkenston.Repo)

    resolve_type fn
      _, _ -> nil
    end
  end
end
