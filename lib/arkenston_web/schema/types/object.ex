defmodule ArkenstonWeb.Schema.Types.Object do
  use Absinthe.Schema.Notation
  use ArkenstonWeb.Schema.Types.AuditedObject

  import_types ArkenstonWeb.Schema.Types.Object.Empty
  import_types ArkenstonWeb.Schema.Types.Object.User
  import_types ArkenstonWeb.Schema.Types.Object.AccessToken
  import_types ArkenstonWeb.Schema.Types.Object.Token
end
