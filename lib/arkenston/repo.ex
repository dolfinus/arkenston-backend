defmodule Arkenston.Repo do
  use Ecto.Repo,
    otp_app: :arkenston,
    adapter: Ecto.Adapters.Postgres

  import Ecto.Query, warn: false

  alias Arkenston.Helper.QueryHelper
  alias Arkenston.Subject.User

  @type author :: User.t | nil
  @type changeset :: Ecto.Changeset.t
  @type operation :: atom

  @spec data(ctx :: map) :: Dataloader.Ecto.t
  def data(context) do
    Dataloader.Ecto.new(__MODULE__, query: &QueryHelper.generate_query/2, default_params: %{context: context})
  end

  @spec audited(op :: operation, author :: author, args :: [any]) :: {:ok, any} | {:error, any}
  defp audited(op, %User{} = author, args) do
    if in_transaction?() do
      query("set local \"arkenston.current_user\" = '#{author.id}';")
      apply(__MODULE__, op, args)
    else
      case transaction(fn ->
        query("set local \"arkenston.current_user\" = '#{author.id}';")
        result = apply(__MODULE__, op, args)

        case result do
          {:ok, result} ->
            {:ok, result}
          {:error, error} ->
            rollback(error)
        end
      end) do
        {:ok, {:ok, _} = success} ->
          success

        {:ok, success} ->
          {:ok, success}

        {:error, {:error, _} = error} ->
          {:error, error}

        {:error, error} ->
          {:error, error}
      end
    end
  end

  defp audited(op, _author, args) do
    apply(__MODULE__, op, args)
  end

  @spec audited_insert(changeset :: changeset, context :: map, opts :: [keyword]) :: {:ok, any} | {:error, any}
  def audited_insert(changeset, context \\ %{}, opts \\ []) do
    author = get_author(context)

    audited(:insert, author, [changeset, opts])
  end

  @spec audited_insert!(changeset :: changeset, context :: map, opts :: [keyword]) :: any | no_return
  def audited_insert!(changeset, context \\ %{}, opts \\ []) do
    case audited_insert(changeset, context, opts) do
      {:ok, result} ->
        result

      {:error, changes} ->
        raise Ecto.InvalidChangesetError, action: :insert, changeset: changes
    end
  end

  @spec audited_update(changeset :: changeset, context :: map, opts :: [keyword]) :: {:ok, any} | {:error, any}
  def audited_update(changeset, context \\ %{}, opts \\ []) do
    author = get_author(context)

    audited(:update, author, [changeset, opts])
  end

  @spec audited_update!(changeset :: changeset, context :: map, opts :: [keyword]) :: any | no_return
  def audited_update!(changeset, context \\ %{}, opts \\ []) do
    case audited_update(changeset, context, opts) do
      {:ok, result} ->
        result

      {:error, changes} ->
        raise Ecto.InvalidChangesetError, action: :update, changeset: changes
    end
  end

  @spec get_author(context :: map) :: author
  defp get_author(%{current_user: %User{} = user}) do
    user
  end

  defp get_author(_) do
    nil
  end
end
