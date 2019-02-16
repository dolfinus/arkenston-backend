class JsonWebToken
  def self.encode(payload, options)
    JWT.encode(payload, options[:secret])
  end

  def self.decode(token, options)
    HashWithIndifferentAccess.new(JWT.decode(token, options[:secret], options)[0])
  end
end
