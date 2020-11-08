defmodule ArkenstonWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :arkenston

  socket "/socket", ArkenstonWeb.UserSocket,
    websocket: true,
    longpoll: false

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json, Absinthe.Plug.Parser],
    pass: ["application/json"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head

  plug Corsica, Application.get_env(:arkenston, ArkenstonWeb.Endpoint)[:cors]

  plug ArkenstonWeb.Router
end
