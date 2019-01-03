class UpdateUserMutator < ApplicationMutator
  parameter :name,         !types.String
  parameter :input,        !Inputs::UpdateUserInputType
  type Types::UserType

  def mutate
    user = User.find_by_name!(params[:name])
    authorize_action! user, :update
    authorize_fields! user, params[:input]

    user.update_attributes(params[:input])
    user.save!
    user
  end
end