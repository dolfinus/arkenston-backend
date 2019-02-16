class UpdateUserMutator < ApplicationMutator
  include UserSeeker
  parameter :input, !Inputs::UpdateUserInputType
  type Types::UserType

  def mutate
    user = find_user_or_current(params)
    authorize_params! user, params[:input], :update
    user.update_attributes(params[:input])
    user.save!
    user
  end
end
