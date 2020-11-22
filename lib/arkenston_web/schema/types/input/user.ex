defmodule ArkenstonWeb.Schema.Types.Input.User do
  use Absinthe.Schema.Notation

  input_object :create_user_author_input do
    field :id,          :uuid4
    field :name,        :string
    field :email,       :string
    field :first_name,  :string
    field :middle_name, :string
    field :last_name,   :string
    field :translations, list_of(non_null(:author_translation_input))
  end

  input_object :change_user_author_input do
    field :id,    :uuid4
    field :name,  :string
    field :email, :string
  end

  input_object :create_user_input do
    field :password, non_null(:string)
    field :role,     :user_role, default_value: :user
    field :note,     :string
  end

  input_object :update_user_input do
    field :password, :string
    field :role,     :user_role
    field :note,     :string
  end

  input_object :delete_user_input do
    field :with_author, :boolean, default_value: true
    field :note, :string
  end
end
