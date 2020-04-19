defmodule Arkenston.Resolver.UserResolver do
  alias Arkenston.Subject
  alias Arkenston.Subject.User

  alias Arkenston.Helper.QueryHelper
  alias Arkenston.Helper.FieldsHelper

  @type where :: QueryHelper.query_opts | map
  @type context :: QueryHelper.fields_opt | %{current_user: User.t}
  @type params :: %{context: context}

  @spec all(where :: where, params :: params) :: {:ok, [User.t]}
  def all(where, %{context: context}) do
    {:ok, Subject.list_users(where, FieldsHelper.prepare_fields(User, context))}
  end

  @spec one(where:: where, params :: params) :: {:ok, User.t | nil}
  def one(%{id: id}, %{context: context}) when not is_nil(id) do
    {:ok, Subject.get_user(id, FieldsHelper.prepare_fields(User, context))}
  end

  def one(where, %{context: context}) when is_map(where) and map_size(where) != 0 do
    {:ok, Subject.get_user_by(where, FieldsHelper.prepare_fields(User, context))}
  end

  def one(_args, %{context: %{current_user: current_user}} = info) when not is_nil(current_user) do
    one(%{id: current_user.id}, info)
  end

  def one(_args, _info) do
    {:error, :invalid_request}
  end
end
