class UserPolicy < ApplicationPolicy
  def create?
    @user.admin? || @user.anonymous?
  end

  def update?
    @user.admin? || @user.moderator? || current?
  end

  def destroy?
    @user.admin? || current?
  end

  def name?
    @user.admin?
  end

  def email?
    update?
  end

  def role?
    name?
  end

  def password?
    @user.admin? || current?
  end

  def remember_token?
    password?
  end

  def confirmation_token?
    create?
  end

  def translations?
    update?
  end

  private

  def current?
    @user == @record && !@user.anonymous?
  end
end
