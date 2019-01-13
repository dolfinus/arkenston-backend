module Auth
  class Error
    NotAuthorized = Class.new(StandardError)

    def self.not_found(value = nil)
      ActiveRecord::RecordNotFound.new('', User.to_s, value, {})
    end

    def self.not_allowed
      Error::NotAuthorized.new
    end
  end
end
