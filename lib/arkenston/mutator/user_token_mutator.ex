defmodule Arkenston.Mutator.UserTokenMutator do
  alias Arkenston.Guardian
  alias Arkenston.Helper.AuthHelper
  alias Arkenston.Subject.User

  @type refresh_token :: %{refresh_token: String.t}
  @type access_token :: %{access_token: String.t}

  @type login_args :: %{email: User.email, password: User.password} | %{name: User.name, password: User.password}
  @type login_result :: %{refresh_token: String.t, access_token: String.t}

  @spec login(args :: login_args, info :: map) :: {:error, any} | {:ok, login_result}
  def login(args, info \\ %{})
  def login(%{password: password} = input, _info) do
    auth = case input do
      %{name: name} ->
        AuthHelper.login_with_name_pass(name, password)
      %{email: email} ->
        AuthHelper.login_with_email_pass(email, password)
    end

    with  {:ok, user} <- auth,
          {:ok, refresh_token, _} <- Guardian.encode_and_sign(user, %{}, token_type: "refresh"),
          {:ok, _old_stuff,  {access_token, _new_claims}} <- Guardian.exchange(refresh_token, "refresh", "access") do
            {:ok, %{refresh_token: refresh_token, access_token: access_token, user: user}}
          else
            error -> error
    end
  end

  @spec exchange(args :: refresh_token, info :: map) :: {:error, any} | {:ok, access_token}
  def exchange(args, info \\ %{})
  def exchange(%{refresh_token: refresh_token}, _info) do
    with  {:ok, claims} <- Guardian.decode_and_verify(refresh_token, %{"typ" => "refresh"}),
          {:ok, user} <- Guardian.resource_from_claims(claims),
          {:ok, _old_stuff, {access_token, _new_claims}} <- Guardian.exchange(refresh_token, "refresh", "access") do
            {:ok, %{access_token: access_token, user: user}}
          else
            error ->
              error
    end
  end

  @type logout_result :: {:ok, any} | {:error, any}
  @spec logout(args :: refresh_token, info :: map) :: {:error, atom} | {:ok, nil}
  def logout(args, info \\ %{})
  def logout(%{refresh_token: token}, _info) do
    with  {:ok, _claims} <- Guardian.decode_and_verify(token, %{"typ" => "refresh"}),
          {:ok, _claims} <- Guardian.revoke(token) do
            {:ok, nil}
          else
            error -> error
    end
  end

  def logout(_args, _info) do
    {:error, "Please log in first!"}
  end
end
