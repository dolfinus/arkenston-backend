module Types
  class BaseInputObject < GraphQL::Schema::InputObject
    include GraphQL::Sugar::Object
  end
end
