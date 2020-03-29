defmodule ArkenstonWeb.Schema.Types.Object do
  use Absinthe.Schema.Notation

  object :session do
    field :token, :string
  end

  object :user do
    field :id, :id
    field :name, :string
    field :email, :string
    field :role, :user_role
    field :deleted, :boolean
  end
end
