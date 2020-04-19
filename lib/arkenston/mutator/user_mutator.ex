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
end
