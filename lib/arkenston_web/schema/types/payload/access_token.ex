defmodule ArkenstonWeb.Schema.Types.Payload.AccessToken do
  use Absinthe.Schema.Notation
  import AbsintheErrorPayload.Payload

  payload_object :access_token_payload, :access_token
end
