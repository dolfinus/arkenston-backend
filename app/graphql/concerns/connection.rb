module Connection
  class << self
    def define(klass)
      Types::ConnectionType.create_type klass do
        field :page_info,   Types::PageInfoType
        field :total_count, !types.Int, property: :total_count
      end
    end
  end
end
