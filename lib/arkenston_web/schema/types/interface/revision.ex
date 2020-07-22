defmodule ArkenstonWeb.Schema.Types.Interface.Revision do
  use Absinthe.Schema.Notation
  use ArkenstonWeb.Schema.Helpers.Association

  interface :revision do
    field :id,         non_null(:uuid4)
    field :version,    non_null(:integer)
    field :created_at, non_null(:datetime)
    field :note,       :string
    field :created_by, :user do
      resolve assoc(:user)
    end

    resolve_type fn
      _, _ -> nil
    end
  end
end
