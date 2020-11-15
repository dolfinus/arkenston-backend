# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

db_user     = System.get_env("POSTGRES_USER")     || "postgres"
db_password = System.get_env("POSTGRES_PASSWORD") || "postgres"
db_name     = System.get_env("POSTGRES_DB")       || "db"
db_host     = System.get_env("POSTGRES_HOST")     || "localhost"

frontend_host   = System.get_env("FRONTENT_HOST")   || "localhost"
frontend_port   = System.get_env("FRONTENT_PORT")   || "80" |> String.to_integer()
frontend_scheme = System.get_env("FRONTENT_SCHEME") || "http"
frontend_path   = System.get_env("FRONTENT_PATH")   || "/"

backend_host   = System.get_env("BACKEND_HOST")   || "localhost"
backend_port   = System.get_env("BACKEND_PORT")   || "3000" |> String.to_integer()
backend_scheme = System.get_env("BACKEND_SCHEME") || "http"
backend_path   = System.get_env("BACKEND_PATH")   || "/api"

locales = ["en", "ru"]
default_locale = System.get_env("BACKEND_LOCALE") || "en"

# Configure your database
config :arkenston, Arkenston.Repo,
  username: db_user,
  password: db_password,
  database: db_name,
  hostname: db_host,
  pool_size: 10

# Configures the endpoint
config :arkenston, ArkenstonWeb.Endpoint,
  url: [
    host:   frontend_host,
    port:   frontend_port,
    scheme: frontend_scheme,
    path:   frontend_path,
  ],
  http: [
    port: backend_port
  ],
  api: [
    host:   backend_host,
    port:   backend_port,
    scheme: backend_scheme,
    path:   backend_path,
  ],
  graphiql_url: "#{backend_scheme}://#{backend_host}:#{backend_port}#{backend_path}/graphql",
  cors: [
    origins: [
      "#{frontend_scheme}://#{frontend_host}:#{frontend_port}",
      "#{frontend_scheme}://#{frontend_host}:#{frontend_port}" |> String.replace(frontend_host, "localhost"),
      "#{frontend_scheme}://#{frontend_host}:#{frontend_port}" |> String.replace(frontend_host, "127.0.0.1"),
      "#{backend_scheme}://#{backend_host}:#{backend_port}",
      "#{backend_scheme}://#{backend_host}:#{backend_port}" |> String.replace(backend_host, "localhost"),
      "#{backend_scheme}://#{backend_host}:#{backend_port}" |> String.replace(backend_host, "127.0.0.1")
    ],
    allow_credentials: true,
    max_age: 86400,
    allow_methods: ["POST", "OPTIONS", "HEAD"],
    allow_headers: ["Content-Type"],
    log: [rejected: :error]
  ]

config :ex_cldr,
  default_locale: default_locale,
  default_backend: Linguist.Cldr

config :linguist,
  pluralization_key: :count

config :linguist, Linguist.Cldr,
  default_locale: default_locale,
  locales: locales,
  force_locale_download: Mix.env() == "prod"

config :arkenston, Arkenston.I18n,
  locale: default_locale

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
