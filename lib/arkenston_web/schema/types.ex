defmodule ArkenstonWeb.Schema.Types do
  defmacro __using__(_opts) do
    quote do
      import_types Absinthe.Type.Custom
      import_types Absinthe.Plug.Types

      import_types ArkenstonWeb.Schema.Types.Custom
      import_types ArkenstonWeb.Schema.Types.Enum
      import_types ArkenstonWeb.Schema.Types.Input
      import_types ArkenstonWeb.Schema.Types.Interface
      import_types ArkenstonWeb.Schema.Types.Node
      import_types ArkenstonWeb.Schema.Types.Object
      import_types ArkenstonWeb.Schema.Types.Payload

      import_types ArkenstonWeb.Schema.Query.User
      import_types ArkenstonWeb.Schema.Query.Author

      import_types ArkenstonWeb.Schema.Mutation.UserToken
      import_types ArkenstonWeb.Schema.Mutation.User
      import_types ArkenstonWeb.Schema.Mutation.Author
    end
  end
end
