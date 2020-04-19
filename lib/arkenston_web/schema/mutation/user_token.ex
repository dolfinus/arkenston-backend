defmodule ArkenstonWeb.Schema.Mutation.UserToken do
  use Absinthe.Schema.Notation
  import AbsintheErrorPayload.Payload

  object :user_token_mutations do
    field :login, :user_token_payload do
      arg :email, :string
      arg :name, :string
      arg :password, non_null(:string)

      resolve &Arkenston.Mutator.UserTokenMutator.login/2
      middleware &build_payload/2
    end

    field :exchange, :user_access_token_payload do
      arg :refresh_token, :string
      resolve &Arkenston.Mutator.UserTokenMutator.exchange/2
      middleware &build_payload/2
    end

    field :logout, :null_payload do
      arg :refresh_token, :string
      resolve &Arkenston.Mutator.UserTokenMutator.logout/2
      middleware &build_payload/2
    end
  end
end
