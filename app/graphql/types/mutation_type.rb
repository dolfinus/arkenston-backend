Types::MutationType = GraphQL::ObjectType.define do
  name 'Mutation'

  mutator :createUser
  mutator :updateUser
  mutator :deleteUser
end
