defmodule Arkenston.Context do
  @behaviour Plug

  import Plug.Conn

  alias Arkenston.Guardian

  def init(opts), do: opts

  @type context :: map

  @spec call(Plug.Conn.t, Plug.opts) :: Plug.Conn.t
  def call(conn, _) do
    case build_context(conn) do
      {:ok, %{} = context} ->
        put_private(conn, :absinthe, %{context: context})
      {:error, _} ->
        conn
    end
  end

  @spec build_context(Plug.Conn.t) :: {:ok, context}|{:error, any}
  defp build_context(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] ->
        case Guardian.decode_and_verify(token) do
          {:ok, claims} ->
            case Guardian.resource_from_claims(claims) do
              {:ok, current_user} ->
                {:ok, %{current_user: current_user, token: token}}
              {:error, error} ->
                {:error, error}
            end
          {:error, error} ->
            {:error, error}
        end
      _ ->
        {:error, :not_authorized}
    end
  end
end
