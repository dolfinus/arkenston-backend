module ModelPagination
  extend ActiveSupport::Concern

  included do
    parameter :first,  types.Int
    parameter :last,   types.Int
    parameter :before, types.ID
    parameter :after,  types.ID
  end

  def resolve
    Types::BaseConnection.new(self.class.model_class.all, params)
  end

  module ClassMethods
    attr_accessor :model_class

    def paginate(klass)
      type "Types::#{klass.to_s.pluralize}Connection".constantize
      @model_class = klass
    end
  end
end
