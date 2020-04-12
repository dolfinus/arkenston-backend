defmodule ArkenstonWeb.Schema.Mutation.Session do
  use Absinthe.Schema.Notation

  object :session_mutations do
    field :login, :session do
      arg :email, non_null(:string)
      arg :password, non_null(:string)

      resolve &Arkenston.Subject.UserResolver.login/2
    end

    field :logout, :user do
      resolve &Arkenston.Subject.UserResolver.logout/2
    end
  end
end
