defmodule Arkenston.Repo do
  use Ecto.Repo,
    otp_app: :arkenston,
    adapter: Ecto.Adapters.Postgres
end
