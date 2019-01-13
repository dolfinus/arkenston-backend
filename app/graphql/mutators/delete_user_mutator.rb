class DeleteUserMutator < ApplicationMutator
  include UserSeeker
  type types.Boolean

  def mutate
    user = find_user!(params)
    authorize_action! user, :destroy
    user.destroy!
  end
end
