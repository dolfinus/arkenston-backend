Inputs::UpdateUserInputType = Inputs::BaseInputObject.define do
  name 'UpdateUserInput'
  model_class User

  parameter :email,        types.String
  parameter :password,     types.String
  parameter :translations, types[Inputs::UserTranslationInputType]
  parameter :role,         types.ID
end
