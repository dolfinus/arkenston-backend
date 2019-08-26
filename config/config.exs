# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :arkenston,
  ecto_repos: [Arkenston.Repo]

# Configure your database
config :arkenston, Arkenston.Repo,
  pool_size: 10

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

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
import_config "runtime.exs"
