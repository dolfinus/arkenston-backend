import Config

# Configure your database
config :arkenston, Arkenston.Repo,
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :arkenston, ArkenstonWeb.Endpoint,
  server: false

# Print only warnings and errors during test
config :logger, level: :warn
