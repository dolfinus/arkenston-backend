defmodule ArkenstonWeb.Schema.Types.Payload do
  use Absinthe.Schema.Notation

  import_types AbsintheErrorPayload.ValidationMessageTypes
  import_types ArkenstonWeb.Schema.Types.Payload.Empty
  import_types ArkenstonWeb.Schema.Types.Payload.User
  import_types ArkenstonWeb.Schema.Types.Payload.AccessToken
  import_types ArkenstonWeb.Schema.Types.Payload.Token
end
