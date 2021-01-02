defmodule ArkenstonWeb.Schema.Types.Object.UserAccessToken do
  use Absinthe.Schema.Notation

  object :user_access_token do
    interface :with_access_token
    interface :with_user

    import_fields :with_access_token
    import_fields :with_user
  end
end
