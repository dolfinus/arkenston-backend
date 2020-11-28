defmodule Arkenston.Guardian do
  require Logger
  alias Arkenston.Subject
  alias Arkenston.Subject.User

  use Guardian,
    otp_app: :arkenston,
    permissions: Arkenston.Permissions.all_permissions()

  use Guardian.Permissions, encoding: Guardian.Permissions.AtomEncoding

  @spec subject_for_token(user :: any, claims :: map) :: {:ok, String.t()} | {:error, atom}
  def subject_for_token(%User{id: id}, _claims) do
    {:ok, "User:#{id}"}
  end

  def subject_for_token(_, _), do: {:error, :unhandled_resource_type}

  @spec resource_from_claims(claims :: map) :: {:ok, %User{}} | {:error, atom}
  def resource_from_claims(%{"sub" => "User:" <> id}) do
    case Subject.get_user(id) do
      %User{} = user ->
        {:ok, user}

      _ ->
        {:error, :no_resource}
    end
  end

  def resource_from_claims(_), do: {:error, :unhandled_resource_type}

  def after_encode_and_sign(resource, claims, token, _options) do
    with {:ok, _} <- Guardian.DB.after_encode_and_sign(resource, claims["typ"], claims, token) do
      {:ok, token}
    end
  end

  def on_verify(claims, token, _options) do
    with {:ok, _} <- Guardian.DB.on_verify(claims, token) do
      {:ok, claims}
    end
  end

  def on_revoke(claims, token, _options) do
    with {:ok, _} <- Guardian.DB.on_revoke(claims, token) do
      {:ok, claims}
    end
  end
end
