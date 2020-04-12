defmodule ArkenstonWeb.Schema.Types.Payload.Empty do
  use Absinthe.Schema.Notation
  import AbsintheErrorPayload.Payload

  payload_object :empty_payload, :empty
end
