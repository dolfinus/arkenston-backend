Types::EntityVersionType = GraphQL::ObjectType.define do
  model_class EntityVersion

  attributes :event, :object, :created_at
  relationship :author
end
