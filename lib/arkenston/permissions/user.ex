defmodule Arkenston.Permissions.User do
  @moduledoc false
  alias Arkenston.Permissions
  alias Arkenston.Guardian
  alias Arkenston.Subject.User
  alias Arkenston.Context
  import Indifferent.Sigils

  @spec all_permissions() :: list(atom)
  def all_permissions() do
    Permissions.all_permissions()[:user]
  end

  @spec permissions_for(user_or_role :: User.t | User.role | :anonymous) :: list(atom)
  def permissions_for(%User{role: role}) do
    permissions_for(role)
  end

  def permissions_for(:anonymous) do
    [
      :create_user
    ]
  end

  def permissions_for(:user) do
    [
      :update_self,
      :change_self_password,
      :delete_self
    ]
  end

  def permissions_for(:moderator) do
    [
      :create_user,
      :create_moderator,
      :update_user,
      :update_moderator,
      :update_self,
      :change_user_password,
      :change_self_password,
      :upgrade_user_to_moderator,
      :delete_user,
      :delete_self
    ]
  end

  def permissions_for(:admin) do
    [
      :create_user,
      :create_moderator,
      :create_admin,
      :update_user,
      :update_moderator,
      :update_admin,
      :update_self,
      :change_user_password,
      :change_moderator_password,
      :change_self_password,
      :upgrade_user_to_moderator,
      :upgrade_user_to_admin,
      :upgrade_moderator_to_admin,
      :downgrade_moderator_to_user,
      :delete_user,
      :delete_moderator,
      :delete_self
    ]
  end

  @spec check_permissions_for(operation :: atom, context :: Context.t, old_entity :: any, new_entity :: any) :: :ok | {:error, %AbsintheErrorPayload.ValidationMessage{}}
  def check_permissions_for(operation, context \\ %{anonymous: true}, old_entity \\ nil, new_entity \\ nil)
  def check_permissions_for(:create, context, user, _) do
    actual_permissions = Permissions.permissions_for(context)
    create_permissions = ["create_#{~i(user.role)}" |> String.to_existing_atom()]

    if Guardian.any_permissions?(actual_permissions, %{user: create_permissions}) do
      :ok
    else
      {:error, %AbsintheErrorPayload.ValidationMessage{field: :role, code: :not_enough_permissions}}
    end
  end

  def check_permissions_for(:update, context, old_user, new_user) do
    actual_permissions = Permissions.permissions_for(context)

    old_role = ~i(old_user.role)
    new_role = ~i(new_user.role)

    is_role_changing = case new_role do
      nil -> false
      new_role ->
        old_role != new_role
    end

    is_password_changing = case ~i(new_user.password) do
      nil ->
        false
      "" ->
        false
      _ ->
        true
    end

    update_user_permissions = unless is_self(context, old_user) do
      if is_role_changing do
        [
          "update_#{new_role}" |> String.to_existing_atom()
        ]
      else
        [
          "update_#{old_role}" |> String.to_existing_atom()
        ]
      end
    else
      [:update_self]
    end

    change_role_permissions = if is_role_changing do
      [
        "upgrade_#{old_role}_to_#{new_role}"   |> String.to_atom(),
        "downgrade_#{old_role}_to_#{new_role}" |> String.to_atom()
      ] |> Enum.filter(fn(permission) ->
        all_permissions() |> Enum.member?(permission)
      end)
    else
      nil
    end

    change_password_permissions = if is_password_changing do
      if is_self(context, old_user) do
        [:change_self_password]
      else
        if is_role_changing do
          ["change_#{new_role}_password" |> String.to_existing_atom()]
        else
          ["change_#{old_role}_password" |> String.to_existing_atom()]
        end
      end
    else
      nil
    end

    update_user_permissions_valid     = Guardian.any_permissions?(actual_permissions, %{user: update_user_permissions})
    change_role_permissions_valid     = if is_nil(change_role_permissions), do: true, else: Guardian.any_permissions?(actual_permissions, %{user: change_role_permissions})
    change_password_permissions_valid = if is_nil(change_password_permissions), do: true, else: Guardian.any_permissions?(actual_permissions, %{user: change_password_permissions})

    unless update_user_permissions_valid do
      {:error, %AbsintheErrorPayload.ValidationMessage{code: :not_enough_permissions}}
    else
      unless change_role_permissions_valid do
        {:error, %AbsintheErrorPayload.ValidationMessage{field: :role, code: :not_enough_permissions}}
      else
        unless change_password_permissions_valid do
          {:error, %AbsintheErrorPayload.ValidationMessage{field: :password, code: :not_enough_permissions}}
        else
          :ok
        end
      end
    end
  end

  def check_permissions_for(:delete, context, user, _) do
    actual_permissions = Permissions.permissions_for(context)
    role = ~i(user.role)

    delete_user_permissions = if is_self(context, user) do
      [:delete_self]
    else
      [
        "delete_#{role}" |> String.to_existing_atom()
      ]
    end

    if Guardian.any_permissions?(actual_permissions, %{user: delete_user_permissions}) do
      :ok
    else
      {:error, %AbsintheErrorPayload.ValidationMessage{code: :not_enough_permissions}}
    end
  end

  defp is_self(context, user) do
    case context do
    %{current_user: current_user} when not is_nil(current_user) ->
      ~i(current_user.id) == ~i(user.id)
    _ ->
      false
    end
  end
end