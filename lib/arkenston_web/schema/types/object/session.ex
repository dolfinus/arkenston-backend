defmodule ArkenstonWeb.Schema.Types.Object.Session do
  use Absinthe.Schema.Notation

  object :session do
    field :token, :string
  end
end
