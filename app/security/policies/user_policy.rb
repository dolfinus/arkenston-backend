class UserPolicy < ApplicationPolicy
  allowed :access

  def create?
    admin? || moderator? || anonymous?
  end

  def update?
    (admin? || moderator? || current?) && not_anonymous?
  end

  def destroy?
    (admin? || current?) && not_anonymous?
  end

  def permitted_attributes_for_access
    attrs = %i[name email role translations versions]
    attrs += [:remember_token] if current?

    attrs
  end

  def permitted_attributes_for_create
    %i[name email role translations password]
  end

  def permitted_attributes_for_update
    attrs = %i[name email role translations]
    attrs += [:password] if current?

    attrs
  end

  def permitted_values_for_role
    roles = User.all_roles
    if @user
      roles = User.all_roles[0..@user.role_id]

      if @record
        # Don't allow do downgrade admin role by moderator
        roles = [] if @record.role_id > @user.role_id
      end
    end

    roles
  end

  def assignable_user_roles
    permitted_values_for_role
  end

  private

  def current?
    return false unless @user && @record

    @user.id == @record.id && not_anonymous?
  end

  def not_anonymous?
    !@record.anonymous? if @record

    true
  end
end
