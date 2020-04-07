defmodule ArkenstonWeb.Schema.Types.Enum.UserRole do
  use Absinthe.Schema.Notation

  enum :user_role do
    value :anonymous, description: "Anonymous"
    value :user, description: "User"
    value :moderator, description: "Moderator"
    value :admin, description: "Admin"
  end
end
