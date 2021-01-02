defmodule ArkenstonWeb.Schema.Types.Interface do
  use Absinthe.Schema.Notation

  import_types ArkenstonWeb.Schema.Types.Interface.Revision
  import_types ArkenstonWeb.Schema.Types.Interface.WithAccessToken
  import_types ArkenstonWeb.Schema.Types.Interface.WithRefreshToken
  import_types ArkenstonWeb.Schema.Types.Interface.WithUser
  import_types ArkenstonWeb.Schema.Types.Interface.WithRevision
end
