class ApplicationPolicy
  include BasePolicy
  attr_reader :user, :record

  restricted :create, :update, :destroy
  alias_method(:new?, :create?) # rubocop:disable Style/Alias
  alias_method(:delete?, :destroy?) # rubocop:disable Style/Alias
  delegate :admin?, :moderator?, :user?, :anonymous?, to: :user

  def initialize(user, record)
    @user = user
    @record = record
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope.all
    end
  end
end
