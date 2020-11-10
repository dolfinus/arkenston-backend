defmodule Arkenston.ReleaseTasks do
  @start_apps [
    :arkenston
  ]

  @repos Application.get_env(:arkenston, :ecto_repos, [])

  @spec migrate(argv :: list) :: no_return
  def migrate(_argv) do
    start_services()

    create_storage()

    run_migrations()

    stop_services()
  end

  @spec seed(argv :: list) :: no_return
  def seed(_argv) do
    start_services()

    run_seeds()

    stop_services()
  end

  defp start_services do
    IO.puts("Starting dependencies...")
    # Start apps necessary for executing migrations
    Enum.each(@start_apps, &Application.ensure_all_started/1)

    # Start the Repo(s) for app
    IO.puts("Connecting to repos...")

    # pool_size can be 1 for ecto < 3.0
    Enum.each(@repos, & &1.start_link(pool_size: 2))
  end

  defp stop_services do
    IO.puts("Success!")
    :init.stop()
  end

  defp create_storage do
    Enum.each(@repos, &create_storage_for/1)
  end

  @spec create_storage_for(repo :: Ecto.Repo.t) :: no_return
  defp create_storage_for(repo) do
    app = Keyword.get(repo.config(), :otp_app)
    IO.puts("Creating storage for #{app}...")
    repo.__adapter__.storage_up(repo.config)
  end

  defp run_migrations do
    Enum.each(@repos, &run_migrations_for/1)
  end

  @spec run_migrations_for(repo :: Ecto.Repo.t) :: no_return
  defp run_migrations_for(repo) do
    app = Keyword.get(repo.config(), :otp_app)
    IO.puts("Running migrations for #{app}...")
    migrations_path = priv_path_for(repo, "migrations")

    Ecto.Migrator.run(repo, [migrations_path], :up, all: true)
  end

  defp run_seeds do
    Enum.each(@repos, &run_seeds_for/1)
  end

  @spec run_seeds_for(repo :: Ecto.Repo.t) :: no_return
  defp run_seeds_for(repo) do
    app = Keyword.get(repo.config(), :otp_app)

    # Run the seed script if it exists
    seed_script = priv_path_for(repo, "seeds.exs")
    if File.exists?(seed_script) do
      IO.puts("Running seed script for #{app}...")
      Code.eval_file(seed_script)
    end
  end

  @spec priv_path_for(repo :: Ecto.Repo.t, filename :: String.t) :: String.t
  defp priv_path_for(repo, filename) do
    app = Keyword.get(repo.config(), :otp_app)

    repo_underscore =
      repo
      |> Module.split()
      |> List.last()
      |> Macro.underscore()

    priv_dir = "#{:code.priv_dir(app)}"

    Path.join([priv_dir, repo_underscore, filename])
  end
end
