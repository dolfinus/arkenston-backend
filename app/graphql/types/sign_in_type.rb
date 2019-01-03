Types::SignInType = GraphQL::ObjectType.define do
  name 'SignIn'
  field :jwt, types.String
end
