class UserResolver < ApplicationResolver
  parameter :id,    types.ID
  parameter :name,  types.String
  parameter :email, types.String

  def resolve
    %i[id name email].each do |attr|
      return User.find_by!("#{attr}": params[attr]) if params[attr]
    end

    current_user
  end
end
