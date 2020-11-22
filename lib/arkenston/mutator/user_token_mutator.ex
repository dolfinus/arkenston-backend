defmodule Arkenston.Mutator.UserTokenMutator do
  alias Arkenston.Guardian
  alias Arkenston.Helper.AuthHelper
  alias Arkenston.Permissions
  alias Arkenston.Subject.User
  alias Arkenston.Subject.Author

  @type refresh_token :: %{refresh_token: String.t}
  @type access_token :: %{access_token: String.t}

  @type login_args :: %{email: Author.email, password: User.password} | %{name: Author.name, password: User.password}
  @type login_result :: %{refresh_token: String.t, access_token: String.t, user: User.t}

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
          permissions <- Permissions.permissions_for(user),
          {:ok, refresh_token, _} <- Guardian.encode_and_sign(user, %{pem: permissions}, token_type: "refresh"),
          {:ok, _old_stuff,  {access_token, _new_claims}} <- Guardian.exchange(refresh_token, "refresh", "access") do
            {:ok, %{refresh_token: refresh_token, access_token: access_token, user: user}}
          else
            {:error, error} -> {:error, %AbsintheErrorPayload.ValidationMessage{code: error}}
    end
  end

  @type exchange_result :: %{access_token: String.t, user: User.t}
  @spec exchange(args :: refresh_token, info :: map) :: {:error, any} | {:ok, exchange_result}
  def exchange(args, info \\ %{})
  def exchange(%{refresh_token: refresh_token}, _info) do
    with  {:ok, claims} <- Guardian.decode_and_verify(refresh_token, %{"typ" => "refresh"}),
          {:ok, user} <- Guardian.resource_from_claims(claims),
          {:ok, _old_stuff, {access_token, _new_claims}} <- Guardian.exchange(refresh_token, "refresh", "access") do
            {:ok, %{access_token: access_token, user: user}}
          else
            {:error, %ArgumentError{message: message}} ->
              {:error, %AbsintheErrorPayload.ValidationMessage{field: :refresh_token, code: message}}
            {:error, "typ"} ->
              {:error, %AbsintheErrorPayload.ValidationMessage{field: :refresh_token, code: :token_type_invalid}}
            {:error, :token_expired} ->
              {:error, %AbsintheErrorPayload.ValidationMessage{field: :refresh_token, code: :token_expired}}
            {:error, error} ->
              {:error, %AbsintheErrorPayload.ValidationMessage{code: error}}
    end
  end

  @spec logout(args :: refresh_token, info :: map) :: {:error, any} | {:ok, nil}
  def logout(args, info \\ %{})
  def logout(%{refresh_token: token}, _info) do
    with  {:ok, _claims} <- Guardian.decode_and_verify(token, %{"typ" => "refresh"}),
          {:ok, _claims} <- Guardian.revoke(token) do
            {:ok, true}
          else
            {:error, %ArgumentError{message: message}} ->
              {:error, %AbsintheErrorPayload.ValidationMessage{field: :refresh_token, code: message}}
            {:error, "typ"} ->
              {:error, %AbsintheErrorPayload.ValidationMessage{field: :refresh_token, code: :token_type_invalid}}
            {:error, :token_expired} ->
              {:error, %AbsintheErrorPayload.ValidationMessage{field: :refresh_token, code: :token_expired}}
            {:error, error} ->
              {:error, %AbsintheErrorPayload.ValidationMessage{code: error}}
    end
  end

  def logout(_args, _info) do
    {:error, "Please log in first!"}
  end
end
