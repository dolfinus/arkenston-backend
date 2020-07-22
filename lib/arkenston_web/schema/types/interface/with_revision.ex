defmodule ArkenstonWeb.Schema.Types.Interface.WithRevision do
  use Absinthe.Schema.Notation
  use ArkenstonWeb.Schema.Helpers.Association

  interface :with_revision do
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
    field :revisions,  non_null(list_of(non_null(:revision))) do
      resolve assoc(:revisions)
    end

    resolve_type fn
      _, _ -> nil
    end
  end
end
