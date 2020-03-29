defmodule Arkenston.Subject.UserResolver do
  alias Arkenston.{AuthHelper, Guardian, Subject}

  def login(%{email: email, password: password}, _info) do
    with  {:ok, user} <- AuthHelper.login_with_email_pass(email, password),
          {:ok, jwt, _} <- Guardian.encode_and_sign(user) do
            {:ok, %{token: jwt}}
    end
  end

  def logout(_args, %{context: %{current_user: current_user, token: _token}}) do
    {:ok, current_user}
  end

  def logout(_args, _info) do
    {:error, "Please log in first!"}
  end

  def prepare_fields(%{fields: fields}), do: fields
  def prepare_fields(_fields), do: []

  def all(%{} = where, %{context: context}) do
    {:ok, Subject.list_users(where, prepare_fields(context))}
  end

  def all(_args, %{context: context}) do
    {:ok, Subject.list_users(%{}, prepare_fields(context))}
  end

  def find(%{id: id}, %{context: context}) when is_integer(id) do
    case Subject.get_user(id, prepare_fields(context)) do
      nil -> {:error, "User id #{id} not found!"}
      user -> {:ok, user}
    end
  end

  def find(%{} = where, %{context: context}) when where != %{} do
    case Subject.get_user_by(where, prepare_fields(context)) do
      nil -> {:error, "User not found!"}
      user -> {:ok, user}
    end
  end

  def find(_args, %{context: %{current_user: current_user}} = info) do
    find(%{id: current_user.id}, info)
  end

  def find(_args, _info) do
    {:error, "Search fields are not set or you've not authorized!"}
  end
end
