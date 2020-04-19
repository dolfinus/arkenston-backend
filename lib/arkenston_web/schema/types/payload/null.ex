defmodule ArkenstonWeb.Schema.Types.Payload.Null do
  use Absinthe.Schema.Notation
  import AbsintheErrorPayload.Payload

  payload_object :null_payload, :null
end
