defmodule ArkenstonWeb.Schema.Types.Custom do
  use Absinthe.Schema.Notation

  import_types ArkenstonWeb.Schema.Types.Custom.UUID4

  import_types ArkenstonWeb.Schema.Types.Custom.NonNegativeInteger
  import_types ArkenstonWeb.Schema.Types.Custom.PositiveInteger
  import_types ArkenstonWeb.Schema.Types.Custom.PageSize
end
