defmodule Arkenston.Permissions.User do
  @moduledoc false
  alias Arkenston.Permissions
  alias Arkenston.Guardian
  alias Arkenston.Subject.User
  alias Arkenston.Context
  import Indifferent.Sigils

  @all_permissions Application.compile_env(:arkenston, [
                     Arkenston.Guardian,
                     :all_permissions,
                     :user
                   ])

  @spec all_permissions() :: Permissions.t()
  def all_permissions do
    @all_permissions
  end

  @spec permissions_for(user_or_role :: User.t() | User.role() | :anonymous) ::
          Permissions.t()
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
      :create_user_with_existing_author,
      :create_moderator,
      :create_moderator_with_existing_author,
      :update_user,
      :update_moderator,
      :update_self,
      :change_user_password,
      :change_self_password,
      :change_user_author,
      :change_self_author,
      :upgrade_user_to_moderator,
      :delete_user,
      :delete_self
    ]
  end

  def permissions_for(:admin) do
    [
      :create_user,
      :create_user_with_existing_author,
      :create_moderator,
      :create_moderator_with_existing_author,
      :create_admin,
      :create_admin_with_existing_author,
      :update_user,
      :update_moderator,
      :update_admin,
      :update_self,
      :change_user_password,
      :change_moderator_password,
      :change_self_password,
      :change_user_author,
      :change_moderator_author,
      :change_self_author,
      :upgrade_user_to_moderator,
      :upgrade_user_to_admin,
      :upgrade_moderator_to_admin,
      :downgrade_moderator_to_user,
      :delete_user,
      :delete_moderator,
      :delete_self
    ]
  end

  @spec check_permissions_for(
          operation :: atom,
          context :: Context.t(),
          old_entity :: any,
          new_entity :: any
        ) :: :ok | {:error, Arkenston.Payload.ValidationMessage.t()}
  def check_permissions_for(:create, context, user, _) do
    actual_permissions = Permissions.permissions_for(context)
    current_user = Permissions.get_current_user(context)

    is_author_other =
      cond do
        is_nil(current_user) ->
          false

        is_nil(user.author) ->
          false

        user.author.created_by_id == current_user.id ->
          false

        true ->
          true
      end

    create_permissions =
      if is_author_other do
        ["create_#{user.role}_with_existing_author" |> String.to_existing_atom()]
      else
        ["create_#{user.role}" |> String.to_existing_atom()]
      end

    if Guardian.any_permissions?(actual_permissions, %{user: create_permissions}) do
      :ok
    else
      {:error, %Arkenston.Payload.ValidationMessage{field: :role, code: :permissions}}
    end
  end

  def check_permissions_for(:update, context, old_user, new_user) do
    actual_permissions = Permissions.permissions_for(context)

    old_role = old_user.role
    new_role = ~i(new_user.role)

    is_role_changing =
      case new_role do
        nil ->
          false

        new_role ->
          old_role != new_role
      end

    is_password_changing =
      case ~i(new_user.password) do
        nil ->
          false

        "" ->
          false

        _ ->
          true
      end

    update_user_permissions =
      unless is_self(context, old_user) do
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

    change_role_permissions =
      if is_role_changing do
        [
          "upgrade_#{old_role}_to_#{new_role}",
          "downgrade_#{old_role}_to_#{new_role}"
        ]
        |> Enum.reduce([], fn permission_str, acc ->
          try do
            acc ++ [permission_str |> String.to_existing_atom()]
          rescue
            ArgumentError ->
              acc
          end
        end)
      else
        nil
      end

    change_password_permissions =
      if is_password_changing do
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

    update_user_permissions_valid =
      Guardian.any_permissions?(actual_permissions, %{user: update_user_permissions})

    change_role_permissions_valid =
      if is_nil(change_role_permissions),
        do: true,
        else: Guardian.any_permissions?(actual_permissions, %{user: change_role_permissions})

    change_password_permissions_valid =
      if is_nil(change_password_permissions),
        do: true,
        else: Guardian.any_permissions?(actual_permissions, %{user: change_password_permissions})

    unless change_role_permissions_valid do
      {:error, %Arkenston.Payload.ValidationMessage{field: :role, code: :permissions}}
    else
      if change_password_permissions_valid and update_user_permissions_valid do
        :ok
      else
        {:error, %Arkenston.Payload.ValidationMessage{code: :permissions}}
      end
    end
  end

  def check_permissions_for(:change_author, context, user, _author) do
    actual_permissions = Permissions.permissions_for(context)

    {change_author_permissions, field, options} =
      unless is_self(context, user) do
        {[
           "change_#{user.role}_author" |> String.to_existing_atom()
         ], :role, [role: {:enum, user.role}]}
      else
        {[:change_self_author], nil, []}
      end

    if Guardian.any_permissions?(actual_permissions, %{user: change_author_permissions}) do
      :ok
    else
      {:error,
       %Arkenston.Payload.ValidationMessage{field: field, code: :permissions, options: options}}
    end
  end

  def check_permissions_for(:delete, context, user, _) do
    actual_permissions = Permissions.permissions_for(context)

    {delete_user_permissions, field, options} =
      if is_self(context, user) do
        {[:delete_self], nil, []}
      else
        {[
           "delete_#{user.role}" |> String.to_existing_atom()
         ], :role, [role: {:enum, user.role}]}
      end

    if Guardian.any_permissions?(actual_permissions, %{user: delete_user_permissions}) do
      :ok
    else
      {:error,
       %Arkenston.Payload.ValidationMessage{field: field, code: :permissions, options: options}}
    end
  end

  defp is_self(context, user) do
    case Permissions.get_current_user(context) do
      nil ->
        false

      current_user ->
        current_user.id == user.id
    end
  end
end
