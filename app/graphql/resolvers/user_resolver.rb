class UserResolver < ApplicationResolver
  parameter :id,   types.ID
  parameter :name, types.String

  def resolve
    if params[:id]
      User.find(params[:id])
    elsif params[:name]
      User.find_by_name(params[:name])
    else
      raise "You should set id or name arguments to find a user!"
    end
  end
end
