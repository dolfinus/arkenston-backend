Types::UserType = GraphQL::ObjectType.define do
  model_class User

  attributes :name, :email, :role
  relationships :translations, :versions
end
