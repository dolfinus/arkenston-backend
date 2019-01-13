class Auth::Basic
  def self.verify(params)
    if params[:header]
      header = params[:header]
      uniq_field, password = ActionController::HttpAuthentication::Basic.user_name_and_password(header)

      User.uniq_fields.each do |attr|
        user = find_and_auth(attr, uniq_field, password)
        return user if user
      end

      raise Auth::Error.not_found

    elsif params[:password]
      password = params[:password]
      attribute = nil

      User.uniq_fields.each do |attr|
        if params[attr]
          attribute = attr
          break
        end
      end

      return find_and_auth(attribute, params[attribute], password) if attribute

      raise Auth::Error.not_found
    end

    Auth::Visitor.anonymous
  end

  def self.find_and_auth(attr, value, password)
    user = User.find_by("#{attr}": value)
    return nil unless user

    raise Auth::Error.not_found unless user.authenticated?(password)

    Auth::Visitor.new(id: user.id, role: user.role)
  end
end
