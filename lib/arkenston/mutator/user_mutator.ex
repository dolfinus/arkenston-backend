defmodule Arkenston.Mutator.UserMutator do
  alias Arkenston.Subject
  alias Arkenston.Subject.User
  alias Arkenston.Permissions

  alias Arkenston.Repo

  @spec create(parent :: any, args :: map, info :: map) :: {:ok, User.t | Ecto.Changeset.t}
  def create(parent \\ nil, args, info \\ %{context: %{anonymous: true}})
  def create(_parent, %{input: attrs, author: author_attrs}, %{context: context}) do
    case Repo.transational(fn ->
      with :ok <- Permissions.check_permissions_for(:user, :create, context, attrs),
          {:ok, author} <- get_or_create_author(author_attrs, context),
          {:ok, user} <- Subject.create_user(attrs |> Map.put(:author_id, author.id), context) do
            {:ok, Subject.get_user(user.id)}
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

  @spec update(parent :: any, args :: map, info :: map) :: {:ok, User.t | Ecto.Changeset.t} | {:error, any}
  def update(parent \\ nil, args, info \\ %{context: %{anonymous: true}})
  def update(_parent, %{input: attrs} = args, %{context: context}) do
    case Repo.transational(fn ->
      case get_user(args, context) do
        {field, nil} ->
          {:error, %AbsintheErrorPayload.ValidationMessage{field: field, code: :not_found}}
        {_field, user} ->
          user = user |> Repo.preload(:author)

          with :ok <- Permissions.check_permissions_for(:user, :update, context, user, attrs),
              {:ok, _user} <- user |> Subject.update_user(attrs, context) do
                {:ok, Subject.get_user(user.id)}
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

  @spec change_author(parent :: any, args :: map, info :: map) :: {:ok, User.t | Ecto.Changeset.t} | {:error, any}
  def change_author(parent \\ nil, args, info \\ %{context: %{anonymous: true}})
  def change_author(_parent, %{author: attrs} = args, %{context: context}) do
    case Repo.transational(fn ->
      case get_user(args, context) do
        {field, nil} ->
          {:error, %AbsintheErrorPayload.ValidationMessage{field: field, code: :not_found}}
        {_field, user} ->
          user = user |> Repo.preload(:author)

          with :ok <- Permissions.check_permissions_for(:user, :change_author, context, user, attrs),
              {:ok, author} <- get_author(attrs),
              {:ok, _user} <- user |> Subject.update_user(%{author_id: author.id}, context) do
                {:ok, Subject.get_user(user.id)}
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

  @spec delete(parent :: any, args :: map, info :: map) :: {:ok, User.t | Ecto.Changeset.t} | {:error, any}
  def delete(parent \\ nil, args, info \\ %{context: %{anonymous: true}})
  def delete(_parent, args, %{context: context}) do
    case Repo.transational(fn ->
      attrs = case args do
        %{input: attrs} ->
          attrs
        _ ->
          %{}
      end

      with_author = case attrs do
        %{with_author: with_author} ->
          with_author
        _ ->
          true
      end

      case get_user(args, context) do
        {field, nil} ->
          {:error, %AbsintheErrorPayload.ValidationMessage{field: field, code: :not_found}}
        {_field, user} ->

          if with_author do
            user = user |> Repo.preload(:author)

            with :ok <- Permissions.check_permissions_for(:user, :delete, context, user, attrs),
                 :ok <- Permissions.check_permissions_for(:author, :delete, context, user.author, attrs),
                {:ok, _user} <- user |> Subject.delete_user(attrs, context),
                {:ok, _user} <- user.author |> Subject.delete_author(attrs, context) do
                  {:ok, true}
            end
          else
            with :ok <- Permissions.check_permissions_for(:user, :delete, context, user, attrs),
                {:ok, _user} <- user |> Subject.delete_user(attrs, context) do
                  {:ok, true}
            end
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

  defp get_user(input, context) do
    case input do
      %{id: id} when not is_nil(id) ->
        {:id, Subject.get_user(id)}
      %{email: email} when not is_nil(email) ->
        author = Subject.get_author_by(email: String.downcase(email))
        user = case author do
          nil ->
            nil
          author ->
            author |> Repo.preload(:user) |> Map.get(:user)
        end
        {:email, user}
      %{name: name} when not is_nil(name) ->
        author = Subject.get_author_by(name: name)
        user = case author do
          nil ->
            nil
          author ->
            author |> Repo.preload(:user) |> Map.get(:user)
        end
        {:name, user}
      _ ->
        case context do
          %{current_user: current_user} ->
            {:access_token, current_user}
          _ ->
            {:access_token, nil}
        end
    end
  end

  defp get_author(attrs) do
    {field, author} = case attrs do
      %{id: id} when not is_nil(id) ->
        {:"author.id", Subject.get_author(id)}
      %{name: name} when not is_nil(name) ->
        {:"author.name", Subject.get_author_by(name: name)}
      %{email: email} when not is_nil(email) ->
        {:"author.email", Subject.get_author_by(email: email)}
      _ ->
        {nil, nil}
    end

    case author do
      nil ->
        {:error, %AbsintheErrorPayload.ValidationMessage{field: field, code: :not_found}}
      author ->
        {:ok, author}
    end
  end

  defp get_or_create_author(attrs, context) do
    case get_author(attrs) do
      {:ok, author} ->
        {:ok, author}
      {:error, _} ->
        Subject.create_author(attrs, context)
    end
  end
end
