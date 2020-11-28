defmodule ArkenstonWeb.Router do
  use ArkenstonWeb, :router

  pipeline :graphql do
    plug Arkenston.Context
  end

  scope "/api" do
    pipe_through :graphql

    forward "/graphql",  Absinthe.Plug,          schema: ArkenstonWeb.Schema, analyze_complexity: true, max_complexity: Application.compile_env(:arkenston, ArkenstonWeb.Endpoint)[:max_complexity]
    forward "/graphiql", Absinthe.Plug.GraphiQL, schema: ArkenstonWeb.Schema, default_url: Application.get_env(:arkenston, ArkenstonWeb.Endpoint)[:graphiql_url], interface: :playground
  end
end
