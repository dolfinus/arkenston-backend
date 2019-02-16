module Types
  # copied from GraphQL::Relay::ConnectionType to use non-camelized page_info fields
  module ConnectionType
    class << self
      attr_accessor :default_nodes_field
      attr_accessor :bidirectional_pagination
    end

    self.default_nodes_field = false
    self.bidirectional_pagination = false

    def self.create_type(wrapped_type, edge_type: nil, edge_class: GraphQL::Relay::Edge, nodes_field: ConnectionType.default_nodes_field, &block)
      custom_edge_class = edge_class

      GraphQL::ObjectType.define do
        type_name = wrapped_type.is_a?(GraphQL::BaseType) ? wrapped_type.name : wrapped_type.graphql_name
        edge_type ||= wrapped_type.edge_type
        name("#{type_name}Connection")
        description("The connection type for #{type_name}.")
        field :edges, types[edge_type], 'A list of edges.', edge_class: custom_edge_class, property: :edge_nodes
        field :nodes, types[wrapped_type],  'A list of nodes.', property: :edge_nodes if nodes_field

        field :page_info, !Types::PageInfoType, 'Information to aid in pagination.', property: :page_info
        relay_node_type(wrapped_type)
        block && instance_eval(&block)
      end
    end
  end
end
