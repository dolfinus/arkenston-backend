module FieldPagination
  def self.call(type_defn, field_name, connection_class = nil)
    paged_field_name = "#{field_name}_paged".to_sym
    connection_class ||= Types::EntityVersionsConnection
    resolve = ->(obj, args, _ctx) { Types::BaseConnection.new(obj.send(field_name), args) }

    GraphQL::Define::AssignObjectField.call type_defn, paged_field_name, type: connection_class, resolve: resolve  do
      parameter :first,  types.Int
      parameter :last,   types.Int
      parameter :before, types.ID
      parameter :after,  types.ID
    end
  end
end
