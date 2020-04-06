# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :arkenston,
  ecto_repos: [Arkenston.Repo],
  users: [
    anonymous: [
      id: "cb51f2d6-3289-4a2a-8212-4762ff0eea5b",
      name: "anonymous",
      email: "anonymous@example.com"
    ],
    admin: [
      name: "admin",
      role: "admin",
      email: "admin@example.com",
      password: "12345678"
    ],
    format: [
      name: ~r/^[a-zA-Z0-9_\-\.]+$/,
      email: ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/
    ]
  ]

# Configure your database
config :arkenston, Arkenston.Repo,
  pool_size: 10,
  migration_timestamps: [type: :utc_datetime],
  migration_primary_key: [name: :id, type: :binary_id, autogenerate: false, read_after_writes: true, default: {:fragment, "gen_random_uuid()"}]

# Configures the endpoint
config :arkenston, ArkenstonWeb.Endpoint,
  render_errors: [view: ArkenstonWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: Arkenston.PubSub, adapter: Phoenix.PubSub.PG2],
  root: ".",
  version: Application.spec(:phoenix_distillery, :vsn)

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Set up Guradian
config :arkenston, Arkenston.Guardian,
  # optional
  allowed_algos: ["HS512"],
  # optional
  verify_module: Guardian.JWT,
  issuer: "Arkenston",
  ttl: {30, :days},
  allowed_drift: 2000,
  # optional
  verify_issuer: true,
  secret_key: %{"k" => Mix.env() |> Atom.to_string(), "kty" => "oct"},
  serializer: Arkenston.Guardian

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
import_config "runtime.exs"
