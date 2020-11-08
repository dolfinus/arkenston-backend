defmodule ArkenstonWeb.Router do
  use ArkenstonWeb, :router
  @api Application.get_env(:arkenston, ArkenstonWeb.Endpoint)[:api]
  @max_complexity Application.get_env(:arkenston, ArkenstonWeb.Endpoint)[:max_complexity]

  pipeline :graphql do
    plug Arkenston.Context
  end

  scope "/api" do
    pipe_through :graphql

    forward "/graphql",  Absinthe.Plug,          schema: ArkenstonWeb.Schema, analyze_complexity: true, max_complexity: @max_complexity
    forward "/graphiql", Absinthe.Plug.GraphiQL, schema: ArkenstonWeb.Schema, default_url: {__MODULE__, :graphiql_default_url}, interface: :playground
  end

  @spec graphiql_default_url :: String.t
  def graphiql_default_url do
    "#{@api[:scheme]}://#{@api[:host]}:#{@api[:port]}#{@api[:path]}/graphql"
  end
end
