module BasePolicy
  extend ActiveSupport::Concern

  included do
    delegate :anybody, to: :class
    delegate :nobody,  to: :class
  end

  module ClassMethods
    def anybody
      true
    end

    def nobody
      false
    end

    def allowed(*methods)
      methods.each do |name|
        alias_method("#{name}?", :anybody)
      end
    end

    def restricted(*methods)
      methods.each do |name|
        alias_method("#{name}?", :nobody)
      end
    end
  end
end
