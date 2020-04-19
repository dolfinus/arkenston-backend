defmodule ArkenstonWeb.Schema.Types.Object do
  use Absinthe.Schema.Notation
  use ArkenstonWeb.Schema.Types.AuditedObject

  import_types ArkenstonWeb.Schema.Types.Object.Null
  import_types ArkenstonWeb.Schema.Types.Object.User
  import_types ArkenstonWeb.Schema.Types.Object.UserAccessToken
  import_types ArkenstonWeb.Schema.Types.Object.UserToken
end
