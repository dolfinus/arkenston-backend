Types::UserType = GraphQL::ObjectType.define do
  model_class User

  attributes :name, :email, :role, :remember_token, resolve_instance_with: :field_policy_check
  relationships :translations, :versions
end
