defmodule ArkenstonWeb.Schema.Helpers.IDTranslator do
  use Memoize
  alias Arkenston.Helper.UUID

  @behaviour Absinthe.Relay.Node.IDTranslator
  @possible_types [:user, :user_revision]

  @spec to_global_id(type :: binary | atom, source_id :: binary, schema :: any) :: {:ok, binary}
  def to_global_id(_type, source_id, _schema) do
    {:ok, source_id}
  end

  @spec from_global_id(global_id :: binary, schema :: any) :: {:error, binary} | {:ok, binary, binary}
  def from_global_id(global_id, _schema) do
    case detect_type(global_id) do
      {:ok, type} ->
        {:ok, type, global_id}
      _ ->
        {:error, "Could not extract value from ID `#{inspect(global_id)}`"}
    end
  end

  defmemop detect_type(global_id) do
    types = @possible_types
    |> Enum.filter(fn type -> UUID.check_uuid(global_id, type) end)

    case types do
      [type] ->
        {:ok, type}
      _ ->
        :error
    end
  end
end
