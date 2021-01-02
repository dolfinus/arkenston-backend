defmodule GraphqlHelper do
  use Phoenix.ConnTest
  import Indifferent.Sigils
  @endpoint ArkenstonWeb.Endpoint

  defmacro __using__(_opts) do
    current = __MODULE__
    quote do
      use Phoenix.ConnTest
      import unquote(current)
    end
  end
  def make_query(conn, query, token \\ nil, locale \\ nil)

  def make_query(conn, query, token, locale) do
    conn = if is_nil(token) do
      conn
    else
      conn |> put_req_header("authorization", "Bearer #{token}")
    end
    conn = if is_nil(locale) do
      conn
    else
      conn |> put_req_header("accept-language", "#{locale}")
    end

    conn
    |> post("/api/graphql", query)
    |> json_response(200)
  end

  def depaginate(result) do
    ~i(result.edges) |> Enum.map(fn edge ->
      ~i(edge.node)
    end)
  end
end
