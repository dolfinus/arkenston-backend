module Types
  class MutationType < GraphQL::Schema::Object
    include GraphQL::Sugar::Mutation
    graphql_name 'Mutation'

    mutator :createUser
    mutator :updateUser
    mutator :deleteUser
  end
end
