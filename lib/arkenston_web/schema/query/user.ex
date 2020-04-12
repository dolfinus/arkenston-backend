defmodule ArkenstonWeb.Schema.Query.User do
  use Absinthe.Schema.Notation

  object :user_queries do
    field :users, list_of(:user) do
      arg :id, :id
      arg :name, :string
      arg :email, :string
      arg :role, :integer
      arg :deleted, :boolean
      resolve &Arkenston.Subject.UserResolver.all/2
    end

    field :user, :user do
      arg :id, :id
      arg :name, :string
      arg :email, :string
      arg :role, :integer
      arg :deleted, :boolean
      resolve &Arkenston.Subject.UserResolver.one/2
    end
  end
end
