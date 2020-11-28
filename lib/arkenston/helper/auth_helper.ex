defmodule Arkenston.Helper.AuthHelper do
  @moduledoc false

  alias Arkenston.Repo
  alias Arkenston.Subject
  alias Arkenston.Subject.User

  @spec login_with_email_pass(email :: String.t, password :: String.t) :: {:error, String.t} | {:ok, User.t}
  def login_with_email_pass(email, password) do
    author = Subject.get_author_by(email: email)

    unless is_nil(author) do
      author = author |> Repo.preload(:user)
      login_with_pass(author.user, password)
    else
      login_with_pass(nil, password)
    end
  end

  @spec login_with_name_pass(name :: String.t, password :: String.t) :: {:error, String.t} | {:ok, User.t}
  def login_with_name_pass(name, password) do
    author = Subject.get_author_by(name: name)

    unless is_nil(author) do
      author = author |> Repo.preload(:user)
      login_with_pass(author.user, password)
    else
      login_with_pass(nil, password)
    end
  end

  defp login_with_pass(%User{} = user, password) do
    if User.check_password(user, password) do
        {:ok, user}
    else
        {:error, "Incorrect login credentials"}
    end
  end

  defp login_with_pass(_user, _password) do
    {:error, "User not found"}
  end
end
