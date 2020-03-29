defmodule Arkenston.AuthHelper do
  @moduledoc false

  alias Arkenston.Repo
  alias Arkenston.Subject.User

  def login_with_pass(%User{} = user, given_pass) do
    cond do
      User.check_password(user, given_pass) ->
        {:ok, user}

      true ->
        {:error, "Incorrect login credentials"}
    end
  end

  def login_with_pass(_user, _given_pass) do
    {:error, "User not found"}
  end

  def login_with_email_pass(email, given_pass) do
    user = Repo.get_by(User, email: String.downcase(email))

    login_with_pass(user, given_pass)
  end

  def login_with_name_pass(name, given_pass) do
    user = Repo.get_by(User, name: name)

    login_with_pass(user, given_pass)
  end
end
