defmodule ArkenstonWeb.Schema.Types.Interface.Revision do
  use Absinthe.Schema.Notation

  interface :revision do
    field :version,    non_null(:integer)
    field :created_by, non_null(:user)
    field :created_at, non_null(:datetime)

    resolve_type fn
      _, _ -> nil
    end
  end
end
