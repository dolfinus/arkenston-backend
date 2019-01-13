Types::RefreshTokenType = GraphQL::ObjectType.define do
  name 'RefreshToken'

  field :refresh_token, types.String
  field :access_token,  types.String
end
