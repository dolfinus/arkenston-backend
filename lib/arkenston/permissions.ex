defmodule Arkenston.Permissions do
  @moduledoc false

  alias Arkenston.Subject.User
  alias Arkenston.Context
  alias Arkenston.Permissions.User, as: UserPermissions
  alias Arkenston.Permissions.Author, as: AuthorPermissions

  @type t :: Guardian.Permissions.input_set()
  @type permissions_map :: Guardian.Permissions.input_permissions()

  @spec permissions_for(user_or_context :: User.t() | :anonymous | Context.t()) :: permissions_map
  def permissions_for(%User{} = user) do
    %{
      user: UserPermissions.permissions_for(user),
      author: AuthorPermissions.permissions_for(user)
    }
  end

  def permissions_for(%{anonymous: false, current_user: %User{} = user}) do
    permissions_for(user)
  end

  def permissions_for(_) do
    %{
      user: UserPermissions.permissions_for(:anonymous),
      author: AuthorPermissions.permissions_for(:anonymous)
    }
  end

  @spec all_permissions() :: permissions_map
  def all_permissions do
    %{
      user: UserPermissions.all_permissions(),
      author: AuthorPermissions.all_permissions()
    }
  end

  @spec check_permissions_for(
          type :: atom,
          operation :: atom,
          context :: Context.t(),
          old_entity :: any,
          new_entity :: any
        ) :: :ok | {:error, Arkenston.Payload.ValidationMessage.t()}
  def check_permissions_for(
        type,
        operation,
        context,
        old_entity \\ nil,
        new_entity \\ nil
      ) do
    case type do
      :user ->
        UserPermissions.check_permissions_for(operation, context, old_entity, new_entity)

      :author ->
        AuthorPermissions.check_permissions_for(operation, context, old_entity, new_entity)
    end
  end

  @spec get_current_user(context :: Context.t()) :: User.t() | nil
  def get_current_user(context) do
    case context do
      %{current_user: user} when not is_nil(user) ->
        user

      _ ->
        nil
    end
  end
end
