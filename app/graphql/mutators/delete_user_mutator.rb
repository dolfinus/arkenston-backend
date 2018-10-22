class DeleteUserMutator < ApplicationMutator
  parameter :name, !types.String
  type              types.Boolean

  def mutate
    user = User.find_by_name(params[:name])
    unless user
      raise "No user with name #{params[:name]}"
    end
    user.destroy
  end
end
