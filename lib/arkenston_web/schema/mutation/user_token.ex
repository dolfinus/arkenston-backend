defmodule ArkenstonWeb.Schema.Mutation.UserToken do
  use Absinthe.Schema.Notation
  import Arkenston.Middleware.HandleErrors

  alias Arkenston.Mutator.UserTokenMutator

  object :user_token_mutations do
    field :login, :user_token do
      arg :email, :string
      arg :name, :string
      arg :password, non_null(:string)

      resolve &UserTokenMutator.login/2
      middleware &build_payload/2
    end

    field :exchange_token, :user_access_token do
      arg :refresh_token, :string
      resolve &UserTokenMutator.exchange_token/2
      middleware &build_payload/2
    end

    field :logout, :user_logout do
      arg :refresh_token, :string
      resolve &UserTokenMutator.logout/2
      middleware &build_payload/2
    end
  end
end
