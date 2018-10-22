class CreateUserMutator < ApplicationMutator
  parameter :name,       !types.String
  parameter :email,      !types.String
  parameter :password,   !types.String
  parameter :locale,     !types.String
  parameter :first_name,  types.String
  parameter :middle_name, types.String
  parameter :last_name,   types.String
  parameter :role,        types.ID
  type Types::UserType

  def mutate
    current_locale = I18n.locale
    if params[:locale]
      I18n.locale = params[:locale]
    end
    user = User.create!(params.select { |key, value| !key.to_s.in?(%w{locale}) })
    I18n.locale = current_locale
    user
  end
end
