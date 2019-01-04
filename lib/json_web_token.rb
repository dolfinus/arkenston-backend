class JsonWebToken
  def self.key
    Rails.application.secrets.secret_key_base
  end

  def self.encode(payload)
    JWT.encode(payload, key)
  end

  def self.decode(token)
    HashWithIndifferentAccess.new(JWT.decode(token, key)[0])
  rescue
    nil
  end
end
