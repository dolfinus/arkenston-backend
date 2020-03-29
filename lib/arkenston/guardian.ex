defmodule Arkenston.Guardian do
  require Logger
  use Guardian, otp_app: :arkenston
  alias Arkenston.Subject

  def subject_for_token(user, _claims) do
    sub = to_string(user.id)
    {:ok, sub}
  end

  def resource_from_claims(claims) do
    user = claims["sub"] |> Subject.get_user()

    {:ok,  user}
  end
end
