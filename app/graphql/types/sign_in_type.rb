Types::SignInType = GraphQL::ObjectType.define do
  name 'SignIn'

  field :refresh_token, types.String
end
