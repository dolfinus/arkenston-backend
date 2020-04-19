defmodule Arkenston.Mutator.UserMutator do
  alias Arkenston.Subject
  alias Arkenston.Subject.User

  @spec create(parent :: any, args :: map, params :: map) :: {:ok, User.t | Ecto.Changeset.t}
  def create(parent \\ nil, args, info \\ %{context: %{}})
  def create(_parent, %{input: attrs}, %{context: context}) do
    case Subject.create_user(attrs, context) do
      {:ok, user} -> {:ok, user}
      {:error, %Ecto.Changeset{} = changeset} -> {:ok, changeset}
    end
  end

  @spec update(parent :: any, args :: map, params :: map) :: {:ok, User.t | Ecto.Changeset.t}
  def update(parent \\ nil, args, info \\ %{context: %{}})
  def update(_parent, %{id: id, input: attrs}, %{context: context}) do
    user = Subject.get_user(id)

    case user |> Subject.update_user(attrs, context) do
      {:ok, user} -> {:ok, user}
      {:error, %Ecto.Changeset{} = changeset} -> {:ok, changeset}
    end
  end

  @spec delete(parent :: any, args :: map, params :: map) :: {:ok, User.t | Ecto.Changeset.t}
  def delete(parent \\ nil, args, info \\ %{context: %{}})
  def delete(_parent, %{id: id}, %{context: context}) do
    user = Subject.get_user(id)

    case user |> Subject.delete_user(context) do
      {:ok, _} -> {:ok, nil}
      {:error, %Ecto.Changeset{} = changeset} -> {:ok, changeset}
    end
  end
end
