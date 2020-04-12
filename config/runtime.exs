# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# Configure your database
config :arkenston, Arkenston.Repo,
  username: System.get_env("POSTGRES_USER")     || "postgres",
  password: System.get_env("POSTGRES_PASSWORD") || "postgres",
  database: System.get_env("POSTGRES_DB")       || "db",
  hostname: System.get_env("POSTGRES_HOST")     || "localhost",
  pool_size: 10

# Configures the endpoint
config :arkenston, ArkenstonWeb.Endpoint,
  url: [
    host:   System.get_env("FRONTENT_HOST")   || "localhost",
    port:   System.get_env("FRONTENT_PORT")   || "80" |> String.to_integer(),
    scheme: System.get_env("FRONTENT_SCHEME") || "http",
    path:   System.get_env("FRONTENT_PATH")   || "/",
  ],
  http: [
    port: 3000
  ],
  api: [
    host:   System.get_env("BACKEND_HOST")   || "localhost",
    port:   System.get_env("BACKEND_PORT")   || "3000" |> String.to_integer(),
    scheme: System.get_env("BACKEND_SCHEME") || "http",
    path:   System.get_env("BACKEND_PATH")   || "/api",
  ]

if Mix.env() == "prod" do
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  config :arkenston, ArkenstonWeb.Endpoint,
    secret_key_base: secret_key_base

  config :arkenston, Arkenston.Guardian,
    secret_key: %{"k" => secret_key_base, "kty" => "oct"}
end
