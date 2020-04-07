defmodule ArkenstonWeb.Schema.Types.Input.User do
  use Absinthe.Schema.Notation

  input_object :input_user do
    field :name,  non_null(:string)
    field :email, non_null(:string)
    field :password, non_null(:string)
    field :role,  :user_role
  end
end
