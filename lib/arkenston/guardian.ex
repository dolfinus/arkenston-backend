defmodule Arkenston.Guardian do
  require Logger
  use Guardian, otp_app: :arkenston
  alias Arkenston.Subject
  alias Arkenston.Subject.User

  @spec subject_for_token(user :: any, claims :: map) :: {:ok, String.t} | {:error, :unknown_subject}
  def subject_for_token(user, _claims) do
    case user do
      %User{} ->
        {:ok, to_string(user.id)}

      _ ->
        {:error, :unknown_subject}
    end
  end

  @spec resource_from_claims(claims :: map) :: {:ok, %User{}} | {:error, :no_resource}
  def resource_from_claims(claims) do
    case Subject.get_user(claims["sub"]) do
      %User{} = user ->
          {:ok, user}
      _ ->
        {:error, :no_resource}
    end
  end
end
