defmodule ArkenstonWeb.Schema.Types.Input.Author do
  use Absinthe.Schema.Notation

  input_object :create_author_input do
    field :name, non_null(:string)
    field :email, non_null(:string)
    field :first_name, :string
    field :middle_name, :string
    field :last_name, :string
    field :translations, list_of(non_null(:author_translation_input))
    field :note, :string
  end

  input_object :update_author_input do
    field :name, :string
    field :email, :string
    field :first_name, :string
    field :middle_name, :string
    field :last_name, :string
    field :translations, list_of(non_null(:author_translation_input))
    field :note, :string
  end

  input_object :delete_author_input do
    field :note, :string
  end
end
