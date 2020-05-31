defmodule ArkenstonWeb.Schema.Types.Object.User do
  use Absinthe.Schema.Notation
  use ArkenstonWeb.Schema.Types.AuditedObject

  audited_object :user do
    field :id,      non_null(:uuid4)
    field :name,    non_null(:string)
    field :email,   non_null(:string)
    field :role,    non_null(:user_role)
    field :deleted, non_null(:boolean)
  end
end
