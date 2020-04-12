defmodule ArkenstonWeb.Schema.Types.Object.AccessToken do
  use Absinthe.Schema.Notation

  object :access_token do
    interface :with_access_token
    import_fields :with_access_token
  end
end
