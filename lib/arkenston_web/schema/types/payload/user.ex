defmodule ArkenstonWeb.Schema.Types.Payload.User do
  use Absinthe.Schema.Notation
  import AbsintheErrorPayload.Payload

  payload_object :user_payload, :user
end
