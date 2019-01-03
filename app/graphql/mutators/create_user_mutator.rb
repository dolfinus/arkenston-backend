class CreateUserMutator < ApplicationMutator
  parameter :input,        !Inputs::CreateUserInputType
  type Types::UserType

  def mutate
    authorize_action! nil, :create,        UserPolicy
    authorize_fields! nil, params[:input], UserPolicy
    user = User.create!(params[:input])
    user
  end
end
