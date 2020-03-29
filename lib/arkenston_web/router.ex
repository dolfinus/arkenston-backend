defmodule ArkenstonWeb.Router do
  use ArkenstonWeb, :router

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
    forward "/graphiql", Absinthe.Plug.GraphiQL, schema: ArkenstonWeb.Schema
  end
end
