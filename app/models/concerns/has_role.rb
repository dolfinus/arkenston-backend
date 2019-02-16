module HasRole
  extend ActiveSupport::Concern

  included do
    assignable_values_for :role, through: proc { find_policy(self) }, default: default_role
  end

  def role_id
    User.all_roles.index(role)
  end

  module ClassMethods
    def all_roles
      %w[user moderator admin]
    end

    def default_role
      all_roles.first
    end

    def anonymous_role
      default_role
    end
  end
end
