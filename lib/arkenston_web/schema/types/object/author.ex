defmodule ArkenstonWeb.Schema.Types.Object.Author do
  use Absinthe.Schema.Notation
  use ArkenstonWeb.Schema.Helpers.Translation

  audited_translated :author do
    field :name, non_null(:string)
    field :email, :string
    field :deleted, non_null(:boolean)
  after
    connect_with :user
    translated :first_name
    translated :middle_name
    translated :last_name
  else
    field :first_name, non_null(:string)
    field :middle_name, non_null(:string)
    field :last_name, non_null(:string)
  end
end
