# Import all plugins from `rel/plugins`
# They can then be used by adding `plugin MyPlugin` to
# either an environment, or release definition, where
# `MyPlugin` is the name of the plugin module.
~w(rel plugins *.exs)
|> Path.join()
|> Path.wildcard()
|> Enum.map(&Code.eval_file(&1))

use Distillery.Releases.Config,
    # This sets the default release built by `mix distillery.release`
    default_release: :default,
    # This sets the default environment used by `mix distillery.release`
    default_environment: Application.get_env(:arkenston, :environment)

# For a full list of config options for both releases
# and environments, visit https://hexdocs.pm/distillery/config/distillery.html


# You may define one or more environments in this file,
# an environment's settings will override those of a release
# when building in that environment, this combination of release
# and environment configuration is called a profile

environment :prod do
  set include_erts: true
  set include_src: false
  set cookie: :";GZV0O2MAw87GHVU(XX!^xNqD8ZUjvV:UHpVgc?]h]4^P{hRkp@vW4c?g2d;2A]Q"
  set vm_args: "rel/vm.args"
end

# You may define one or more releases in this file.
# If you have not set a default release, or selected one
# when running `mix distillery.release`, the first release in the file
# will be used by default

release :arkenston do
  set version: current_version(:arkenston)
  set config_providers: [
    {Distillery.Releases.Config.Providers.Elixir, ["${RELEASE_ROOT_DIR}/etc/config.exs"]}
  ]
  set overlays: [
    {:copy, "config/runtime.exs", "etc/config.exs"}
  ]
  set pre_configure_hooks: "rel/hooks/pre_configure"
  set post_configure_hooks: "rel/hooks/post_configure"
  set pre_start_hooks: "rel/hooks/pre_start"
  set post_start_hooks: "rel/hooks/post_start"
  set commands: [
    migrate: "rel/commands/migrate.sh",
    seed: "rel/commands/seed.sh",
  ]
  set applications: [
    :runtime_tools
  ]
end
