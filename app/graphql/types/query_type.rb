module Types
  class QueryType < GraphQL::Schema::Object
    graphql_name "Query"

    resolver :user
  end
end