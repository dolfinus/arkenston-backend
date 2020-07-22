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
      preferred_cli_env: [espec: :test, coveralls: :test, "coveralls.detail": :test, "coveralls.post": :test, "coveralls.html": :test],
      spec_paths: ["spec"],
      spec_pattern: "*_{factory,spec,helper}.{ex,exs}",
      test_coverage: [
        tool: ExCoveralls,
        test_task: "espec"
      ],
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
        ignore_warnings: ".dialyzer_ignore.exs"
      ]
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
        :absinthe_plug,
        :indifferent
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
      {:phoenix, "~> 1.4.16"},
      {:phoenix_pubsub, "~> 1.1"},
      {:phoenix_ecto, "~> 4.1"},
      {:ecto_sql, "~> 3.4"},
      {:postgrex, "~> 0.15"},
      {:jason, "~> 1.2"},
      {:plug_cowboy, "~> 2.1"},
      {:absinthe, "~> 1.5"},
      {:absinthe_plug, "~> 1.5"},
      {:absinthe_error_payload, "~> 1.1"},
      {:absinthe_relay, "~> 1.5"},
      {:dataloader, "~> 1.0"},
      {:distillery, "~> 2.1", only: :prod},
      {:p1_utils, "~> 1.0"},
      {:trans, "~> 2.2"},
      {:ecto_enum, "~> 1.4"},
      {:argon2_elixir, "~> 2.3"},
      {:pbkdf2_elixir, "~> 1.2"},
      {:inflex, "~> 2.0" },
      {:linguist, "~> 0.3"},
      {:ex_cldr, "~> 2.13", override: true},
      {:guardian, "~> 2.1"},
      {:guardian_phoenix, "~> 2.0"},
      {:guardian_db, "~> 2.0"},
      {:indifferent, "~> 0.9"},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:faker, "~> 0.13", only: :test},
      {:ex_machina, "~> 2.4", only: :test},
      {:espec, "~> 1.8", only: :test},
      {:excoveralls, "~> 0.12", only: :test},
      {:uuid, "~> 1.1"}
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
      test: ["ecto.reset", "espec --cover"]
    ]
  end
end
