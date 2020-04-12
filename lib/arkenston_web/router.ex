defmodule ArkenstonWeb.Router do
  use ArkenstonWeb, :router
  @api Application.get_env(:arkenston, ArkenstonWeb.Endpoint)[:api]

  pipeline :graphql do
    plug Plug.Parsers,
      parsers: [:urlencoded, :multipart, :json, Absinthe.Plug.Parser],
      pass: ["*/*"],
      json_decoder: Jason

    plug Arkenston.Context
  end

  scope "/api" do
    pipe_through :graphql

    forward "/graphql",  Absinthe.Plug,          schema: ArkenstonWeb.Schema
    forward "/graphiql", Absinthe.Plug.GraphiQL, schema: ArkenstonWeb.Schema, default_url: {__MODULE__, :graphiql_default_url}, interface: :playground
  end

  @spec graphiql_default_url :: String.t
  def graphiql_default_url do
    "#{@api[:scheme]}://#{@api[:host]}:#{@api[:port]}#{@api[:path]}/graphql"
  end
end
