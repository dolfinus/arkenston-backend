module Types
  class QueryType < GraphQL::Schema::Object

    field :user, Types::UserType, null: true do
      description "Find a user"
      argument :id,             ID,     required: false
      argument :name,           String, required: false
      argument :remember_token, String, required: false
    end

    def user(**args)
      if args[:id]
        User.find(args[:id])
      elsif args[:name]
        User.find_by(name: args[:name])
      elsif args[:remember_token]
        User.find_by(remember_token: args[:remember_token])
      end
    end
  end
end