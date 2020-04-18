defmodule ArkenstonWeb.Schema.Mutation.Token do
  use Absinthe.Schema.Notation
  import AbsintheErrorPayload.Payload

  object :token_mutations do
    field :login, :user_token_payload do
      arg :email, :string
      arg :name, :string
      arg :password, non_null(:string)

      resolve &Arkenston.Subject.UserResolver.login/2
      middleware &build_payload/2
    end

    field :exchange, :user_access_token_payload do
      arg :refresh_token, :string
      resolve &Arkenston.Subject.UserResolver.exchange/2
      middleware &build_payload/2
    end

    field :logout, :empty_payload do
      arg :refresh_token, :string
      resolve &Arkenston.Subject.UserResolver.logout/2
      middleware &build_payload/2
    end
  end
end
