class SignInResolver < ApplicationResolver
  parameter :id,       types.ID
  parameter :name,     types.String
  parameter :email,    types.String
  parameter :password, types.String
  parameter :token,    types.String

  def resolve
    puts params
    [:id, :name, :email].each do |attr|
      if params[attr] && params[:password]
        user = User.find_by!({"#{attr}": params[attr]})
        unless user.authenticated?(params[:password])
          raise ActiveRecord::RecordNotFound.new('', User.to_s, params[attr], params)
        else
          return user
        end
      end
    end
    if params[:token]
      return User.find_by_remember_token!(params[:token])
    else
      return current_user
    end
  end
end
