defmodule ArkenstonWeb.Schema.Types.Input do
  use Absinthe.Schema.Notation

  import_types ArkenstonWeb.Schema.Types.Input.Author
  import_types ArkenstonWeb.Schema.Types.Input.User
end
