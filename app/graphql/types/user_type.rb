Types::UserType = GraphQL::ObjectType.define do
  model_class User

  attributes :name, :email, :role, :remember_token, resolve_instance_with: :field_policy_check
  attributes :created_at, :updated_at
  relationships :translations, :versions
end
