module Auth
  class Token

    def self.generate(user)
      payload = {user_id: user.id}
      JsonWebToken.encode(payload)
    end

    def self.verify(token)
      result = JsonWebToken.decode(token)
      return nil unless result

      begin
        user = User.find(result[:user_id])
      rescue
        user = User.anonymous
      end
      user
    end

  end
end