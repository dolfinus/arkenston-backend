defmodule ArkenstonWeb.Schema.Types.Interface.WithUser do
  use Absinthe.Schema.Notation

  interface :with_user do
    field :user, non_null(:user)

    resolve_type fn
      _, _ -> nil
    end
  end
end
