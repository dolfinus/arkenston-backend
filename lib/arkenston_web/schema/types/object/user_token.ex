defmodule ArkenstonWeb.Schema.Types.Object.UserToken do
  use Absinthe.Schema.Notation

  object :user_token do
    interface :with_refresh_token
    interface :with_access_token
    interface :with_user

    import_fields :with_refresh_token
    import_fields :with_access_token
    import_fields :with_user
  end
end
