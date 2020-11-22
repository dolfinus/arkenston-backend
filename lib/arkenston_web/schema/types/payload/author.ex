defmodule ArkenstonWeb.Schema.Types.Payload.Author do
  use Absinthe.Schema.Notation
  import AbsintheErrorPayload.Payload

  payload_object :author_payload, :author
end
