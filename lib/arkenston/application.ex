defmodule Arkenston.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Start the Ecto repository
      Arkenston.Repo,
      # Start the endpoint when the application starts
      ArkenstonWeb.Endpoint,
      # Starts a worker by calling: Arkenston.Worker.start_link(arg)
      # {Arkenston.Worker, arg},
      {Guardian.DB.Sweeper, []}
      # Start the Absinthe schema when the application starts
      # uncomment after solving https://github.com/absinthe-graphql/absinthe/issues/1054
      # {Absinthe.Schema, ArkenstonWeb.Schema}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Arkenston.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    ArkenstonWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
