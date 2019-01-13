class Auth::Token
  def self.config(type = :access)
    raw_config = Settings.token[type]

    cfg = OpenStruct.new(secret: raw_config.secret, expire: raw_config.expire)
    if raw_config[:issuer]
      cfg.iss = raw_config.issuer
      cfg.verify_iss = true
    end

    cfg
  end

  def self.generate(user, type = :access)
    cfg = config(type)
    payload = {
      sub: user.id,
      aud: user.role,
      exp: Time.now.to_i + cfg.expire,
      iss: cfg.iss
    }
    JsonWebToken.encode(payload, cfg)
  end

  def self.verify(token, type = :access)
    return Auth::Visitor.anonymous unless token

    result = JsonWebToken.decode(token, config(type))
    Auth::Visitor.new(id: result[:sub], role: result[:aud])
  end
end
