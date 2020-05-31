defmodule GraphqlHelper do
  use Phoenix.ConnTest
  @endpoint ArkenstonWeb.Endpoint

  defmacro __using__(_opts) do
    current = __MODULE__
    quote do
      use Phoenix.ConnTest
      import unquote(current)
    end
  end

  def make_query(conn, query) do
    conn
    |> post("/api/graphql", query)
    |> json_response(200)
  end

  def make_query(conn, query, token) do
    conn
    |> put_req_header("authorization", "Bearer #{token}")
    |> post("/api/graphql", query)
    |> json_response(200)
  end
end
