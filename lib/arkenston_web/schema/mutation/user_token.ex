defmodule ArkenstonWeb.Schema.Mutation.UserToken do
  use Absinthe.Schema.Notation
  import AbsintheErrorPayload.Payload

  alias Arkenston.Mutator.UserTokenMutator

  object :user_token_mutations do
    field :login, :user_token_payload do
      arg :email, :string
      arg :name, :string
      arg :password, non_null(:string)

      resolve &UserTokenMutator.login/2
      middleware &build_payload/2
    end

    field :exchange, :user_access_token_payload do
      arg :refresh_token, :string
      resolve &UserTokenMutator.exchange/2
      middleware &build_payload/2
    end

    field :logout, :boolean_payload do
      arg :refresh_token, :string
      resolve &UserTokenMutator.logout/2
      middleware &build_payload/2
    end
  end
end
