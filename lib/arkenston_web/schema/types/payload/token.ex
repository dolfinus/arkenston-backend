defmodule ArkenstonWeb.Schema.Types.Payload.Token do
  use Absinthe.Schema.Notation
  import AbsintheErrorPayload.Payload

  payload_object :token_payload, :token
end
