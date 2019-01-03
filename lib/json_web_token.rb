class JsonWebToken

  def self.key
    Rails.application.secrets.secret_key_base
  end

  def self.encode(payload)
    JWT.encode(payload, self.key)
  end

  def self.decode(token)
    return HashWithIndifferentAccess.new(JWT.decode(token, self.key)[0])
  rescue
    nil
  end
end