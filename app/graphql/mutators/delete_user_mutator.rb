class DeleteUserMutator < ApplicationMutator
  parameter :name, types.String
  type types.Boolean

  def mutate
    user = User.find_by!(name: params[:name])
    authorize_action! user, :destroy
    user.destroy!
  end
end
