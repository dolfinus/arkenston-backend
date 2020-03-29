defmodule ArkenstonWeb.Schema.Types do
  defmacro __using__(_opts) do
    quote do
      import_types Absinthe.Type.Custom
      import_types Absinthe.Plug.Types

      import_types ArkenstonWeb.Schema.Types.Enum
      import_types ArkenstonWeb.Schema.Types.Object
    end
  end
end
