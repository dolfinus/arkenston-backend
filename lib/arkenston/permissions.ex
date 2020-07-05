defmodule Arkenston.Permissions do
  @moduledoc false

  alias Arkenston.Subject.User
  alias Arkenston.Context
  alias Arkenston.Permissions.User, as: UserPermissions

  @type permissions :: %{optional(atom) => [atom] | %{atom => integer()}}

  @spec permissions_for(user_or_context :: User.t | :anonymous | Context.t) :: permissions
  def permissions_for(%User{} = user) do
    %{
      user: UserPermissions.permissions_for(user)
    }
  end

  def permissions_for(:anonymous) do
    %{
      user: UserPermissions.permissions_for(:anonymous)
    }
  end

  def permissions_for(%{anonymous: false, current_user: %User{} = user}) do
    permissions_for(user)
  end

  def permissions_for(%{anonymous: true}) do
    permissions_for(:anonymous)
  end

  @all_permissions Application.get_env(:arkenston, Arkenston.Guardian)[:all_permissions]

  @spec all_permissions() :: permissions
  def all_permissions() do
    @all_permissions
  end

  @spec check_permissions_for(type :: atom, operation :: atom, context :: Context.t, old_entity :: any, new_entity :: any) :: :ok | {:error, %AbsintheErrorPayload.ValidationMessage{}}
  def check_permissions_for(type, operation, context \\ %{anonymous: true}, old_entity \\ nil, new_entity \\ nil) do
    case type do
      :user ->
        UserPermissions.check_permissions_for(operation, context, old_entity, new_entity)
    end
  end
end
