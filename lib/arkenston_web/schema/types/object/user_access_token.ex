defmodule ArkenstonWeb.Schema.Types.Object.UserAccessToken do
  use Absinthe.Schema.Notation

  object :user_access_token do
    interface :with_access_token
    import_fields :with_access_token

    field :user, non_null(:user)
  end
end
