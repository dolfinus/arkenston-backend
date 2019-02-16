class Auth::Basic
  def self.verify(params)
    if params[:password]
      password = params[:password]
      attribute = nil

      User.uniq_fields.each do |attr|
        if params[attr]
          attribute = attr
          break
        end
      end

      return find_and_auth(attribute, params[attribute], password) if attribute
    end

    Auth::Visitor.anonymous
  end

  def self.find_and_auth(attr, value, password)
    user = User.find_by("#{attr}": value)
    raise Auth::Error.not_found unless user
    raise Auth::Error.not_found unless user.authenticated?(password)

    Auth::Visitor.new(id: user.id, role: user.role)
  end
end
