defmodule ArkenstonWeb.Schema.Types.Object.Author do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern
  use ArkenstonWeb.Schema.Helpers.Association
  use ArkenstonWeb.Schema.Helpers.Translation

  audited_translated_object :author do
    field :name,        non_null(:string)
    field :email,       non_null(:string)
    field :first_name,  non_null(:string)
    field :middle_name, non_null(:string)
    field :last_name,   non_null(:string)
    field :deleted,     non_null(:boolean)
  else # translation fields
    field :first_name,  non_null(:string)
    field :middle_name, non_null(:string)
    field :last_name,   non_null(:string)
  after # resolvers
    connect_with(:user)
    translate(:first_name)
    translate(:middle_name)
    translate(:last_name)
  end
end