defmodule Arkenston.Helper.AuthHelper do
  @moduledoc false

  alias Arkenston.Subject
  alias Arkenston.Subject.User

  @spec login_with_pass(user :: User.t, password :: String.t) :: {:error, String.t} | {:ok, User.t}
  def login_with_pass(%User{} = user, password) do
    cond do
      User.check_password(user, password) ->
        {:ok, user}

      true ->
        {:error, "Incorrect login credentials"}
    end
  end

  def login_with_pass(_user, _password) do
    {:error, "User not found"}
  end

  @spec login_with_email_pass(email :: String.t, password :: String.t) :: {:error, String.t} | {:ok, User.t}
  def login_with_email_pass(email, password) do
    user = Subject.get_user_by(email: String.downcase(email))

    login_with_pass(user, password)
  end

  @spec login_with_name_pass(name :: String.t, password :: String.t) :: {:error, String.t} | {:ok, User.t}
  def login_with_name_pass(name, password) do
    user = Subject.get_user_by(name: name)

    login_with_pass(user, password)
  end
end
