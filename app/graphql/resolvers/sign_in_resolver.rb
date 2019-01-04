class SignInResolver < ApplicationResolver
  parameter :id,       types.ID
  parameter :name,     types.String
  parameter :email,    types.String
  parameter :password, types.String
  parameter :token,    types.String

  def resolve
    %i[id name email].each do |attr|
      if params[attr] && params[:password]
        user = User.find_by!("#{attr}": params[attr])
        raise ActiveRecord::RecordNotFound.new('', User.to_s, params[attr], params) unless user.authenticated?(params[:password])

        return user
      end
    end
    return User.find_by!(remember_token: params[:token]) if params[:token]

    current_user
  end
end
