defmodule Arkenston.Context do
  @behaviour Plug

  import Plug.Conn

  alias Arkenston.Guardian
  alias Arkenston.I18n
  alias Arkenston.Subject.User

  @type t ::
          %{
            anonymous: false,
            current_user: User.t(),
            token: String.t(),
            permissions: map,
            locale: String.t()
          }
          | %{anonymous: true, locale: String.t()}

  def init(opts), do: opts

  @spec call(Plug.Conn.t(), Plug.opts()) :: Plug.Conn.t()
  def call(conn, _) do
    {:ok, context} = build_context(conn)
    put_private(conn, :absinthe, %{context: context})
  end

  @spec build_context(Plug.Conn.t()) :: {:ok, t} | {:error, any}
  defp build_context(conn) do
    locale = get_locale_from_header(conn)

    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, claims} <- Guardian.decode_and_verify(token, %{"typ" => "access"}),
         {:ok, current_user} <- Guardian.resource_from_claims(claims),
         permissions <- Guardian.decode_permissions_from_claims(claims) do
      {:ok,
       %{
         anonymous: false,
         current_user: current_user,
         token: token,
         permissions: permissions,
         locale: locale
       }}
    else
      _ ->
        {:ok, %{anonymous: true, locale: locale}}
    end
  end

  @spec get_locale_from_header(Plug.Conn.t()) :: String.t() | nil
  defp get_locale_from_header(conn) do
    conn
    |> I18n.extract_accept_language()
    |> Enum.find(nil, &supported_locale?/1)
  end

  @spec supported_locale?(String.t()) :: boolean
  defp supported_locale?(locale), do: Enum.member?(I18n.all_locales(), locale)
end
