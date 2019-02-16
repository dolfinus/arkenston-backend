Types::QueryType = GraphQL::ObjectType.define do
  name 'Query'

  resolver :user
  resolver :users
  resolver :signIn
  resolver :refreshToken
end
