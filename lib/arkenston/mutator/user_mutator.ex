defmodule Arkenston.Mutator.UserMutator do
  alias Arkenston.Subject
  alias Arkenston.Subject.User
  alias Arkenston.Permissions

  @spec create(parent :: any, args :: map, info :: map) :: {:ok, User.t | Ecto.Changeset.t}
  def create(parent \\ nil, args, info \\ %{context: %{anonymous: true}})
  def create(_parent, %{input: attrs}, %{context: context}) do
    with :ok <- Permissions.check_permissions_for(:user, :create, context, attrs),
        {:ok, user} <- Subject.create_user(attrs, context) do
          {:ok, Subject.get_user(user.id)}
    else
      {:error, %Ecto.Changeset{} = changeset}
        ->
          {:ok, changeset}
      error
        ->
          error
    end
  end

  @spec update(parent :: any, args :: map, info :: map) :: {:ok, User.t | Ecto.Changeset.t} | {:error, any}
  def update(parent \\ nil, args, info \\ %{context: %{anonymous: true}})
  def update(_parent, %{input: attrs} = args, %{context: context}) do
    case get_user(args, context) do
      {field, nil} ->
        {:error, %AbsintheErrorPayload.ValidationMessage{field: field, code: :not_found}}
      {_field, user} ->
        with :ok <- Permissions.check_permissions_for(:user, :update, context, user, attrs),
            {:ok, _user} <- user |> Subject.update_user(attrs, context) do
              {:ok, Subject.get_user(user.id)}
        else
          {:error, %Ecto.Changeset{} = changeset}
            ->
              {:ok, changeset}
          error
            ->
              error
        end
    end
  end

  @spec delete(parent :: any, args :: map, info :: map) :: {:ok, User.t | Ecto.Changeset.t} | {:error, any}
  def delete(parent \\ nil, args, info \\ %{context: %{anonymous: true}})
  def delete(_parent, args, %{context: context}) do
    attrs = case args do
      %{input: attrs} ->
        attrs
      _ ->
        %{}
    end

    case get_user(args, context) do
      {field, nil} ->
        {:error, %AbsintheErrorPayload.ValidationMessage{field: field, code: :not_found}}
      {_field, user} ->
        with :ok <- Permissions.check_permissions_for(:user, :delete, context, user, args),
            {:ok, _user} <- user |> Subject.delete_user(attrs, context) do
              {:ok, nil}
        else
          {:error, %Ecto.Changeset{} = changeset}
            ->
              {:ok, changeset}
          error
            ->
              error
        end
    end
  end

  defp get_user(input, context) do
    case input do
      %{id: id} when not is_nil(id) ->
        {:id, Subject.get_user(id)}
      %{name: name} when not is_nil(name) ->
        {:name, Subject.get_user_by(name: name)}
      %{email: email} when not is_nil(email) ->
        {:email, Subject.get_user_by(email: String.downcase(email))}
      _ ->
        case context do
          %{current_user: current_user} ->
            {:access_token, current_user}
          _ ->
            {:access_token, nil}
        end
    end
  end
end
