defmodule ArkenstonWeb.Schema.Types.Interface.WithRevision do
  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  interface :with_revision do
    field :version,    non_null(:integer)
    field :created_at, non_null(:datetime)
    field :updated_at, :datetime
    field :note,       :string
    field :created_by, :user, resolve: dataloader(Arkenston.Repo)
    field :updated_by, :user, resolve: dataloader(Arkenston.Repo)
    field :revisions,  non_null(list_of(non_null(:revision))), resolve: dataloader(Arkenston.Repo)

    resolve_type fn
      _, _ -> nil
    end
  end
end
