Inputs::CreateUserInputType = Inputs::BaseInputObject.define do
  name 'CreateUserInput'
  model_class User

  parameter :name,         !types.String
  parameter :email,        !types.String
  parameter :password,     !types.String
  parameter :translations, !types[Inputs::UserTranslationInputType]
  parameter :role,          Types::UserRoleType
end
