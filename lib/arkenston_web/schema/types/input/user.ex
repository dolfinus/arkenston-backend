defmodule ArkenstonWeb.Schema.Types.Input.User do
  use Absinthe.Schema.Notation

  input_object :create_user_input do
    field :name,     non_null(:string)
    field :email,    non_null(:string)
    field :password, non_null(:string)
    field :role,     non_null(:user_role), default_value: :user
    field :note,    :string
  end

  input_object :update_user_input do
    field :name,     :string
    field :email,    :string
    field :password, :string
    field :role,     :user_role
    field :note,     :string
  end

  input_object :delete_user_input do
    field :note, :string
  end
end
