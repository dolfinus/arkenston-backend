module Types
  class UserRoleType < BaseEnum
    value 'ADMIN', value: :admin
    value 'MODERATOR', value: :moderator
    value 'USER', value: :user
  end
end
