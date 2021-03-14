defmodule ArkenstonWeb.Schema.Types.Object.User do
  use Absinthe.Schema.Notation
  use ArkenstonWeb.Schema.Helpers.Revision

  audited :user do
    field :role, non_null(:user_role)
    field :deleted, non_null(:boolean)

    connect_with_audited :author
    connect_with_field_audited :author, :name, non_null(:string)
    connect_with_field_audited :author, :email, non_null(:string)
  end
end
