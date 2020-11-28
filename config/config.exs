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
    admin: [
      role: "admin",
      password: "12345678"
    ],
    length: [
      password: 6
    ]
  ],
  authors: [
    admin: [
      name: "admin",
      email: "admin@example.com"
    ],
    format: [
      name: ~r/^[a-zA-Z0-9_\-\.]+$/,
      email: ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/
    ]
  ]

# Configure your database
config :arkenston, Arkenston.Repo,
  pool_size: 10,
  migration_timestamps: [type: :utc_datetime],
  migration_primary_key: [
    name: :id,
    type: :binary_id,
    autogenerate: false,
    read_after_writes: true,
    default: {:fragment, "gen_random_uuid()"}
  ]

config :arkenston, ArkenstonWeb.Endpoint,
  page_size: 20,
  max_page_size: 5000,
  max_complexity: 5000,
  render_errors: [view: ArkenstonWeb.ErrorView, accepts: ~w(json)]

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
  ttl: {15, :minutes},
  token_ttl: %{
    refresh: {60, :days},
    restore: {1, :days},
    signin: {1, :days}
  },
  allowed_drift: 2000,
  # optional
  verify_issuer: true,
  secret_key: %{"k" => Mix.env() |> Atom.to_string(), "kty" => "oct"},
  serializer: Arkenston.Guardian,
  # append-only list, never change order of items
  all_permissions: %{
    user: [
      :create_user,
      :create_moderator,
      :create_admin,
      :create_user_with_existing_author,
      :create_moderator_with_existing_author,
      :create_admin_with_existing_author,
      :change_self_author,
      :update_user,
      :update_moderator,
      :update_admin,
      :update_self,
      :change_user_password,
      :change_moderator_password,
      :change_admin_password,
      :change_self_password,
      :change_user_author,
      :change_moderator_author,
      :change_admin_author,
      :change_self_author,
      :upgrade_user_to_moderator,
      :upgrade_user_to_admin,
      :upgrade_moderator_to_admin,
      :downgrade_admin_to_moderator,
      :downgrade_admin_to_user,
      :downgrade_moderator_to_user,
      :delete_user,
      :delete_moderator,
      :delete_admin,
      :delete_self
    ],
    author: [
      :create_author,
      :update_unassigned_author,
      :update_user_author,
      :update_moderator_author,
      :update_admin_author,
      :update_self,
      :delete_unassigned_author,
      :delete_user_author,
      :delete_moderator_author,
      :delete_admin_author,
      :delete_self
    ]
  }

config :guardian, Guardian.DB,
  # Add your repository module
  repo: Arkenston.Repo,
  # default
  schema_name: "guardian_tokens",
  # store all token types if not set
  token_types: ["refresh", "restore", "signin"],
  # default: 60 minutes
  sweep_interval: 60

config :linguist, pluralization_key: :count

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
import_config "runtime.exs"
