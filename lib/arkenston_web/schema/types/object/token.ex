defmodule ArkenstonWeb.Schema.Types.Object.Token do
  use Absinthe.Schema.Notation

  object :token do
    interface :with_refresh_token
    interface :with_access_token

    import_fields :with_refresh_token
    import_fields :access_token
  end
end
