class UserResolver < ApplicationResolver
  parameter :id,    types.ID
  parameter :name,  types.String
  parameter :email, types.String

  def resolve
    [:id, :name, :email].each do |attr|
      if params[attr]
        return User.find_by!({"#{attr}": params[attr]})
      end
    end
    return current_user
  end
end
