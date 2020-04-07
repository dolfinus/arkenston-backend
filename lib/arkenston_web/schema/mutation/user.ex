defmodule ArkenstonWeb.Schema.Mutation.User do
  use Absinthe.Schema.Notation
  import AbsintheErrorPayload.Payload

  object :user_mutations do
    field :create_user, :user_payload do
      arg :input, non_null(:input_user)
      resolve &Arkenston.Subject.UserResolver.create/3
      middleware &build_payload/2
    end
  end
end
