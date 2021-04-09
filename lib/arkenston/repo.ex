defmodule Arkenston.Repo do
  use Ecto.Repo,
    otp_app: :arkenston,
    adapter: Ecto.Adapters.Postgres

  import Ecto.Query, warn: false

  alias Arkenston.Helper.QueryHelper
  alias Arkenston.Subject.User

  @type user :: User.t() | nil
  @type changeset :: Ecto.Changeset.t()
  @type operation :: atom

  @spec data() :: Dataloader.Ecto.t()
  def data do
    Dataloader.Ecto.new(__MODULE__,
      query: &QueryHelper.generate_query/2
    )
  end

  @spec detect_rollback(callback :: term) :: {:ok, any} | no_return
  def detect_rollback(result) do
    case result do
      {:error, error} ->
        rollback(error)

      :error ->
        rollback(:unknown_error)

      result ->
        result
    end
  end

  defmacro within_transaction(do: block) do
    do_within_transaction(block)
  end

  defmacro within_transaction(input) do
    do_within_transaction(
      quote do
        unquote(input).()
      end
    )
  end

  def do_within_transaction(block) do
    quote do
      result = unquote(block)

      detect_rollback(result)
    end
  end

  defmacro new_transaction(do: block) do
    do_new_transaction(block)
  end

  defmacro new_transaction(input) do
    do_new_transaction(
      quote do
        unquote(input).()
      end
    )
  end

  def do_new_transaction(input) do
    quote do
      case transaction(fn ->
             result = unquote(input)

             detect_rollback(result)
           end) do
        {:ok, {:ok, _} = success} ->
          success

        {:ok, success} ->
          {:ok, success}

        {:error, {:error, _} = error} ->
          error

        {:error, error} ->
          {:error, error}
      end
    end
  end

  def transational(args \\ []) do
    if in_transaction?() do
      within_transaction(args)
    else
      new_transaction(args)
    end
  end

  @spec audited(op :: operation, user :: user, args :: [any]) :: {:ok, any} | {:error, any}
  # sobelow_skip ["SQL.Query"]
  defp audited(op, %User{} = user, args) do
    transational(fn ->
      query("set local \"arkenston.current_user\" = '#{user.id}';")
      apply(__MODULE__, op, args)
    end)
  end

  defp audited(op, _user, args) do
    apply(__MODULE__, op, args)
  end

  @spec audited_insert(changeset :: changeset, context :: map, opts :: [keyword]) ::
          {:ok, any} | {:error, any}
  def audited_insert(changeset, context \\ %{}, opts \\ []) do
    created_by = get_user(context)

    audited(:insert, created_by, [changeset, opts])
  end

  @spec audited_update(changeset :: changeset, context :: map, opts :: [keyword]) ::
          {:ok, any} | {:error, any}
  def audited_update(changeset, context \\ %{}, opts \\ []) do
    updated_by = get_user(context)

    audited(:update, updated_by, [changeset, opts])
  end

  @spec get_user(context :: map) :: user
  defp get_user(%{current_user: %User{} = user}) do
    user
  end

  defp get_user(_) do
    nil
  end
end
