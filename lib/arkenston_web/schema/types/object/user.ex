defmodule ArkenstonWeb.Schema.Types.Object.User do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern
  use ArkenstonWeb.Schema.Helpers.Revision

  audited_object :user do
    field :name,    non_null(:string)
    field :email,   non_null(:string)
    field :role,    non_null(:user_role)
    field :deleted, non_null(:boolean)
  end
end
