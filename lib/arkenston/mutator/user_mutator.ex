defmodule Arkenston.Mutator.UserMutator do
  alias Arkenston.Subject
  alias Arkenston.Subject.User

  @spec create(parent :: any, args :: map, params :: map) :: {:ok, User.t | Ecto.Changeset.t}
  def create(parent \\ nil, args, info \\ %{context: %{}})
  def create(_parent, %{input: attrs}, %{context: context}) do
    case Subject.create_user(attrs, context) do
      {:ok, user} -> {:ok, Subject.get_user(user.id)}
      {:error, %Ecto.Changeset{} = changeset} -> {:ok, changeset}
    end
  end

  @spec update(parent :: any, args :: map, params :: map) :: {:ok, User.t | Ecto.Changeset.t} | {:error, any}
  def update(parent \\ nil, args, info \\ %{context: %{}})
  def update(_parent, %{input: attrs} = args, %{context: context}) do
    with  user when not is_nil(user) <- get_user(args, context),
          {:ok, user} <- user |> Subject.update_user(attrs, context) do
            {:ok, Subject.get_user(user.id)}
    else
          {:error, %Ecto.Changeset{} = changeset} ->
            {:ok, changeset}
          nil ->
            {:error, :not_found}
    end
  end

  @spec delete(parent :: any, args :: map, params :: map) :: {:ok, User.t | Ecto.Changeset.t} | {:error, any}
  def delete(parent \\ nil, args, info \\ %{context: %{}})
  def delete(_parent, args, %{context: context}) do
    attrs = case args do
      %{input: attrs} ->
        attrs
      _ ->
        %{}
    end

    with  user when not is_nil(user) <- get_user(args),
          {:ok, _user} <- user |> Subject.delete_user(attrs, context) do
            {:ok, nil}
    else
          {:error, %Ecto.Changeset{} = changeset} ->
            {:ok, changeset}
          nil ->
            {:error, :not_found}
    end
  end

  defp get_user(input, context) do
    case input do
      %{id: id} when not is_nil(id) ->
        Subject.get_user(id)
      %{name: name} when not is_nil(name) ->
        Subject.get_user_by(name: name)
      %{email: email} when not is_nil(email) ->
        Subject.get_user_by(email: String.downcase(email))
      _ ->
        case context do
          %{current_user: current_user} ->
            current_user
          _ ->
            nil
        end
    end
  end
end
