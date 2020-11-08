import Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with webpack to recompile .js and .css sources.

# Configure your database
config :arkenston, :environment, :dev

config :arkenston, Arkenston.Repo,
  show_sensitive_data_on_connection_error: true

secret_key_base =
  System.get_env("SECRET_KEY_BASE") || "mo0gu8Aem0eiv3xe1coh4uch5Ooti6ye"

config :arkenston, ArkenstonWeb.Endpoint,
  secret_key_base: secret_key_base

config :arkenston, ArkenstonWeb.Endpoint,
  server: true,
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: []

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime
