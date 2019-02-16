# Class for JWT auth without db access
class Auth::Visitor
  attr_reader :id, :role, :user

  def initialize(params = {})
    @id = params[:id]
    @role = params[:role]
    @user = nil
  end

  def self.anonymous
    new(id: User.anonymous_id, role: User.anonymous_role)
  end

  def access_token
    Auth::Token.generate(self, :access) unless anonymous?
  end

  def refresh_token
    Auth::Token.generate(self, :refresh) unless anonymous?
  end

  def anonymous?
    @id == User.anonymous_id
  end

  def admin?
    @role == 'admin'
  end

  def moderator?
    @role == 'moderator'
  end

  def user?
    @role == 'user'
  end

  def role_id
    User.all_roles.index(@role)
  end

  def self.respond_to_missing?(method, include_private = false)
    super
  end

  def self.method_missing(method, *args, &block) # rubocop:disable Style/MethodMissingSuper
    User.public_send(method, *args, &block)
  end

  def self.policy_class
    UserPolicy
  end

  private

  def respond_to_missing?(method, include_private = false)
    methods.include?(method) || super
  end

  def method_missing(method, *args, &block) # rubocop:disable Style/MethodMissingSuper
    @user ||= User.find(@id)
    @user.public_send(method, *args, &block)
  end
end
