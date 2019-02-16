class Schema < GraphQL::Schema
  max_depth Settings.graphql.max_depth
  max_complexity Settings.graphql.max_complexity
  default_max_page_size Settings.graphql.max_page_size

  mutation(Types::MutationType)
  query(Types::QueryType)
end

GraphQL::ObjectType.accepts_definitions(paginate: FieldPagination)
