defmodule Arkenston.Mutator.AuthorMutator do
  alias Arkenston.Repo
  alias Arkenston.Subject
  alias Arkenston.Subject.Author
  alias Arkenston.Permissions

  alias Arkenston.Repo

  @spec create(parent :: any, args :: map, info :: map) :: {:ok, Author.t | Ecto.Changeset.t}
  def create(parent \\ nil, args, info \\ %{context: %{anonymous: true}})
  def create(_parent, %{input: attrs}, %{context: context}) do
    case Repo.transational(fn ->
      with :ok <- Permissions.check_permissions_for(:author, :create, context, attrs),
          {:ok, author} <- Subject.create_author(attrs, context) do
            {:ok, Subject.get_author(author.id)}
      end
    end) do
      {:ok, result} ->
        {:ok, result}
      {:error, %Ecto.Changeset{} = changeset} ->
        {:ok, changeset}
      error ->
          error
    end
  end

  @spec update(parent :: any, args :: map, info :: map) :: {:ok, Author.t | Ecto.Changeset.t} | {:error, any}
  def update(parent \\ nil, args, info \\ %{context: %{anonymous: true}})
  def update(_parent, %{input: attrs} = args, %{context: context}) do
    case Repo.transational(fn ->
      case get_author(args, context) do
        {field, nil} ->
          {:error, %AbsintheErrorPayload.ValidationMessage{field: field, code: :not_found}}
        {_field, author} ->
        with :ok <- Permissions.check_permissions_for(:author, :update, context, author, attrs),
            {:ok, _author} <- author |> Subject.update_author(attrs, context) do
              {:ok, Subject.get_author(author.id)}
          end
      end
    end) do
      {:ok, result} ->
        {:ok, result}
      {:error, %Ecto.Changeset{} = changeset} ->
        {:ok, changeset}
      error ->
          error
    end
  end

  @spec delete(parent :: any, args :: map, info :: map) :: {:ok, Author.t | Ecto.Changeset.t} | {:error, any}
  def delete(parent \\ nil, args, info \\ %{context: %{anonymous: true}})
  def delete(_parent, args, %{context: context}) do
    attrs = case args do
      %{input: attrs} ->
        attrs
      _ ->
        %{}
    end

    case Repo.transational(fn ->
      case get_author(args, context) do
        {field, nil} ->
          {:error, %AbsintheErrorPayload.ValidationMessage{field: field, code: :not_found}}
        {_field, author} ->
          with :ok <- Permissions.check_permissions_for(:author, :delete, context, author, args),
              {:ok, _author} <- author |> Subject.delete_author(attrs, context) do
                {:ok, true}
          end
      end
    end) do
      {:ok, result} ->
        {:ok, result}
      {:error, %Ecto.Changeset{} = changeset} ->
        {:ok, changeset}
      error ->
          error
    end
  end

  defp get_author(input, context) do
    case input do
      %{id: id} when not is_nil(id) ->
        {:id, Subject.get_author(id)}
      %{name: name} when not is_nil(name) ->
        {:name, Subject.get_author_by(name: name)}
      %{email: email} when not is_nil(email) ->
        {:name, Subject.get_author_by(email: email)}
      _ ->
        case context do
          %{current_user: current_user} when not is_nil(current_user) ->
            current_user = current_user |> Repo.preload(:author)
            {:access_token, current_user.author}
          _ ->
            {:access_token, nil}
        end
    end
  end
end
