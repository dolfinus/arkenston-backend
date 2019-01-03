Types::UserTranslationType = GraphQL::ObjectType.define do
  model_class User::Translation, 'UserTranslation'

  attributes :first_name, :middle_name, :last_name, :locale, :created_at, :updated_at
  relationships :versions
end
