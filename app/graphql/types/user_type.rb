module Types
  class UserType < GraphQL::Schema::Object
    graphql_name "User"

    field :id,                 ID,       null: false
    field :name,               String,   null: false
    #field :role,               RoleType, null: false
    field :email,              String,   null: false
    field :password,           String,   null: true
    field :first_name,         String,   null: true
    field :middle_name,        String,   null: true
    field :last_name,          String,   null: true
    field :remember_token,     String,   null: true
    field :confirmation_token, String,   null: true
  end
end
