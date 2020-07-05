defmodule Arkenston.Context do
  @behaviour Plug

  import Plug.Conn

  alias Arkenston.Guardian
  alias Arkenston.Subject.User

  def init(opts), do: opts

  @type t :: %{anonymous: false, current_user: User.t, token: String.t, permissions: map} | %{anonymous: true}

  @spec call(Plug.Conn.t, Plug.opts) :: Plug.Conn.t
  def call(conn, _) do
    with {:ok, %{} = context} <- build_context(conn) do
        put_private(conn, :absinthe, %{context: context})
    else
        _ ->
          conn
    end
  end

  @spec build_context(Plug.Conn.t) :: {:ok, t} | {:error, any}
  defp build_context(conn) do
    with  ["Bearer " <> token] <- get_req_header(conn, "authorization"),
          {:ok, claims} <- Guardian.decode_and_verify(token, %{"typ" => "access"}),
          {:ok, current_user} <- Guardian.resource_from_claims(claims),
          permissions <- Guardian.decode_permissions_from_claims(claims) do
            {:ok, %{anonymous: false, current_user: current_user, token: token, permissions: permissions}}
    else
      _ ->
            {:ok, %{anonymous: true}}
    end
  end
end
