defmodule ArkenstonWeb.Schema.Types.Payload.UserToken do
  use Absinthe.Schema.Notation
  import AbsintheErrorPayload.Payload

  payload_object :user_token_payload, :user_token
end
