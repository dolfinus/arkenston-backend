class UserPolicy < ApplicationPolicy
  def permitted_attributes_for_access
    attrs = %i[name email role translations versions]
    attrs += [:remember_token] if current?

    attrs
  end

  def create?
    admin? || moderator? || anonymous?
  end

  def permitted_attributes_for_create
    %i[name email role translations password]
  end

  def update?
    (admin? || moderator? || current?) && not_anonymous?
  end

  def permitted_attributes_for_update
    attrs = %i[name email role translations]
    attrs += [:password] if current?

    attrs
  end

  def destroy?
    (admin? || current?) && not_anonymous?
  end

  def permitted_values_for_role
    roles = User.all_roles
    roles = User.all_roles[0..@user.role_id] if @user

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
    !@record.anonymous?
  end
end
