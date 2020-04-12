defmodule Arkenston.Subject.UserResolver do
  alias Arkenston.{AuthHelper, Guardian, Subject}
  alias Arkenston.Subject.User

  @type refresh_token :: %{refresh_token: String.t}
  @type access_token :: %{access_token: String.t}

  @type login_args :: %{email: User.email, password: User.password} | %{name: User.name, password: User.password}
  @type login_result :: %{refresh_token: String.t, access_token: String.t}

  @spec login(args :: login_args, info :: map) :: {:error, any} | {:ok, login_result}
  def login(args), do: login(args, %{})
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
            {:ok, %{
              refresh_token: refresh_token,
              access_token: access_token
            }}
          else
            error -> error
    end
  end

  @spec exchange(args :: refresh_token, info :: map) :: {:error, any} | {:ok, access_token}
  def exchange(args), do: exchange(args, %{})
  def exchange(%{refresh_token: refresh_token}, _info) do
    with  {:ok, _claims} <- Guardian.decode_and_verify(refresh_token, %{"typ" => "refresh"}),
          {:ok, _old_stuff, {access_token, _new_claims}} <- Guardian.exchange(refresh_token, "refresh", "access") do
            {:ok, %{
              access_token: access_token
            }}
          else
            error ->
              error
    end
  end

  @type logout_result :: {:ok, any} | {:error, any}
  @spec logout(args :: refresh_token, info :: map) :: {:error, atom} | {:ok, nil}
  def logout(args), do: logout(args, %{})
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

  @spec prepare_fields(map) :: any
  def prepare_fields(%{fields: fields}), do: fields
  def prepare_fields(_fields), do: []

  @spec all(where :: map, params :: map) :: {:ok, [Arkenston.Subject.User.t()]}
  def all(args \\ %{}), do: all(args, %{context: %{}})
  def all(where, %{context: context}) when is_map(where) do
    {:ok, Subject.list_users(where, prepare_fields(context))}
  end

  def all(_args, %{context: context}) do
    {:ok, Subject.list_users(%{}, prepare_fields(context))}
  end

  @spec one(where:: map, params :: map) :: {:error, String.t} | {:ok, User.t} | {:error, any}
  def one(args), do: one(args, %{context: %{}})
  def one(%{id: id}, %{context: context}) when not is_nil(id) do
    case Subject.get_user(id, prepare_fields(context)) do
      nil -> {:error, :not_found}
      user -> {:ok, user}
    end
  end

  def one(where, %{context: context}) when is_map(where) and map_size(where) != 0 do
    case Subject.get_user_by(where, prepare_fields(context)) do
      nil -> {:error, :not_found}
      user -> {:ok, user}
    end
  end

  def one(_args, %{context: %{current_user: current_user}} = info) when not is_nil(current_user) do
    one(%{id: current_user.id}, info)
  end

  def one(_args, _info) do
    {:error, :invalid_request}
  end

  @spec create(parent :: any, args :: map, params :: map) :: {:ok, User.t | Ecto.Changeset.t}
  def create(args), do: create(nil, args, %{context: %{}})
  def create(_parent, %{input: attrs}, %{context: context}) do
    case Subject.create_user(attrs, context) do
      {:ok, user} -> {:ok, user}
      {:error, %Ecto.Changeset{} = changeset} -> {:ok, changeset}
    end
  end
end
