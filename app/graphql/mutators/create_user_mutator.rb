class CreateUserMutator < ApplicationMutator
  parameter :input, !Inputs::CreateUserInputType
  type Types::UserType

  def mutate
    authorize_action! nil, :create, UserPolicy
    authorize_params! nil, params[:input], :create, UserPolicy
    user = User.create!(current_user: current_user, **params[:input])

    user
  end
end
