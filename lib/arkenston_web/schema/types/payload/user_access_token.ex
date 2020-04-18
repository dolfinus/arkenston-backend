defmodule ArkenstonWeb.Schema.Types.Payload.UserAccessToken do
  use Absinthe.Schema.Notation
  import AbsintheErrorPayload.Payload

  payload_object :user_access_token_payload, :user_access_token
end
