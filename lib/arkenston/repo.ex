defmodule Arkenston.Repo do
  use Ecto.Repo,
    otp_app: :arkenston,
    adapter: Ecto.Adapters.Postgres

  require Logger

  alias Arkenston.Subject.User

  defp audited(op, %User{} = user, args) do
    if in_transaction?() do
      query("set local \"arkenston.current_user\" = '#{user.id}';")
      apply(__MODULE__, op, args)
    else
      transaction(fn ->
        query("set local \"arkenston.current_user\" = '#{user.id}';")
        apply(__MODULE__, op, args)
      end)
    end
  end

  defp audited(op, _, args) do
    apply(__MODULE__, op, args)
  end

  def audited_insert(changeset, user \\ %{}, opts \\ []) do
    audited(:insert, user, [changeset, opts])
  end

  def audited_insert!(changeset, user \\ %{}, opts \\ []) do
    case audited_insert(changeset, user, opts) do
      {:ok, struct} ->
        struct

      {:error, changes} ->
        raise Ecto.InvalidChangesetError, action: :insert, changeset: changes
    end
  end

  def audited_update(changeset, user \\ %{}, opts \\ []) do
    audited(:update, user, [changeset, opts])
  end

  def audited_update!(changeset, user \\ %{}, opts \\ []) do
    case audited_update(changeset, user, opts) do
      {:ok, struct} ->
        struct

      {:error, changes} ->
        raise Ecto.InvalidChangesetError, action: :update, changeset: changes
    end
  end
end
