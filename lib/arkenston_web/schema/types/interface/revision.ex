defmodule ArkenstonWeb.Schema.Types.Interface.Revision do
  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  interface :revision do
    field :id,         non_null(:uuid4)
    field :version,    non_null(:integer)
    field :created_at, non_null(:datetime)
    field :note,       :string
    field :created_by, :user, resolve: dataloader(Arkenston.Repo)

    resolve_type fn
      _, _ -> nil
    end
  end
end
