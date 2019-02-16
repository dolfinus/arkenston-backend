Inputs::UserTranslationInputType = Inputs::BaseInputObject.define do
  name 'UserTranslationInput'
  model_class User::Translation

  parameter :locale,     !types.String
  parameter :first_name,  types.String
  parameter :last_name,   types.String
  parameter :middle_name, types.String
end
