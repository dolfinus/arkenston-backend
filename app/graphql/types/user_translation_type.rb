Types::UserTranslationType = GraphQL::ObjectType.define do
  model_class User::Translation, 'UserTranslation'

  attributes
  relationships
end
