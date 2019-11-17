defmodule Arkenston.MixProject do
  use Mix.Project

  def project do
    [
      app: :arkenston,
      version: "0.1.0",
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      preferred_cli_env: [espec: :test],
      spec_paths: ["spec"],
      spec_pattern: "*_{factory,spec,helper}.{ex,exs}",
      test_coverage: [tool: Coverex.Task, coveralls: true]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Arkenston.Application, []},
      extra_applications: [
        :logger,
        :runtime_tools,
        :absinthe_plug
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "priv/repo/migration.ex", "priv/i18n.ex", "test/support"]
  defp elixirc_paths(_), do: ["lib", "priv/repo/migration.ex", "priv/i18n.ex"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.4.9"},
      {:phoenix_pubsub, "~> 1.1"},
      {:phoenix_ecto, "~> 4.0"},
      {:ecto_sql, "~> 3.1"},
      {:postgrex, "~> 0.15"},
      {:jason, "~> 1.1"},
      {:plug_cowboy, "~> 2.0"},
      {:absinthe, "~> 1.4"},
      {:absinthe_plug, "~> 1.4"},
      {:distillery, "~> 2.0", only: :prod},
      {:fast_yaml, "~> 1.0"},
      {:p1_utils, "~> 1.0"},
      {:trans, "~> 2.0"},
      {:ecto_enum, "~> 1.3"},
      {:argon2_elixir, "~> 2.0"},
      {:inflex, "~> 2.0.0" },
      {:linguist, github: "yogodoshi/linguist", branch: "cm/fix-elixir-1.7-compatibility"},
      {:faker, "~> 0.13", only: :test},
      {:ex_machina, "~> 2.3", only: :test},
      {:espec, "~> 1.7.0", only: :test},
      {:propcheck, "~> 1.1", only: :test},
      {:coverex, "~> 1.4.10", only: :test}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.setup", "espec --cover"]
    ]
  end
end
