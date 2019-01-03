Types::QueryType = GraphQL::ObjectType.define do
  name "Query"

  resolver :user
  resolver :users
  resolver :sign_in
end