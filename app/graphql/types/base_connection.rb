class Types::BaseConnection < GraphQL::Relay::RelationConnection
  def total_count
    nodes.size
  end
end