defmodule ArkenstonWeb.Schema.Types.Object.UserLogout do
  use Absinthe.Schema.Notation

  object :user_logout do
    interface :with_user

    import_fields :with_user
  end
end
