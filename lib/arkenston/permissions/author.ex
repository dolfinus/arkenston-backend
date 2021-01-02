defmodule Arkenston.Permissions.Author do
  @moduledoc false
  alias Arkenston.Permissions
  alias Arkenston.Guardian
  alias Arkenston.Subject.User
  alias Arkenston.Context
  alias Arkenston.Repo

  @all_permissions Application.compile_env(:arkenston, [
                     Arkenston.Guardian,
                     :all_permissions,
                     :author
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
    []
  end

  def permissions_for(:user) do
    [
      :create_author,
      :update_unassigned_author,
      :update_self,
      :delete_unassigned_author,
      :delete_self
    ]
  end

  def permissions_for(:moderator) do
    [
      :create_author,
      :update_unassigned_author,
      :update_user_author,
      :update_self,
      :delete_unassigned_author,
      :delete_user_author,
      :delete_self
    ]
  end

  def permissions_for(:admin) do
    [
      :create_author,
      :update_unassigned_author,
      :update_user_author,
      :update_moderator_author,
      :update_self,
      :delete_unassigned_author,
      :delete_user_author,
      :delete_moderator_author,
      :delete_self
    ]
  end

  @spec check_permissions_for(
          operation :: atom,
          context :: Context.t(),
          old_entity :: any,
          new_entity :: any
        ) :: :ok | {:error, %AbsintheErrorPayload.ValidationMessage{}}
  def check_permissions_for(
        operation,
        context \\ %{anonymous: true},
        old_entity \\ nil,
        new_entity \\ nil
      )

  def check_permissions_for(:create, context, _, _) do
    actual_permissions = Permissions.permissions_for(context)
    create_permissions = [:create_author]

    if Guardian.any_permissions?(actual_permissions, %{author: create_permissions}) do
      :ok
    else
      {:error, %AbsintheErrorPayload.ValidationMessage{code: :not_enough_permissions}}
    end
  end

  def check_permissions_for(:update, context, author, _) do
    actual_permissions = Permissions.permissions_for(context)
    author = author |> Repo.preload(:user)

    update_author_permissions =
      cond do
        is_nil(author.user) ->
          [:update_unassigned_author]

        is_self(context, author) ->
          [:update_self]

        true ->
          ["update_#{author.user.role}_author" |> String.to_existing_atom()]
      end

    if Guardian.any_permissions?(actual_permissions, %{author: update_author_permissions}) do
      :ok
    else
      {:error, %AbsintheErrorPayload.ValidationMessage{code: :not_enough_permissions}}
    end
  end

  def check_permissions_for(:delete, context, author, _) do
    actual_permissions = Permissions.permissions_for(context)
    author = author |> Repo.preload(:user)

    delete_author_permissions =
      cond do
        is_nil(author.user) ->
          [:delete_unassigned_author]

        is_self(context, author) ->
          [:delete_self]

        true ->
          ["delete_#{author.user.role}_author" |> String.to_existing_atom()]
      end

    if Guardian.any_permissions?(actual_permissions, %{author: delete_author_permissions}) do
      :ok
    else
      {:error, %AbsintheErrorPayload.ValidationMessage{code: :not_enough_permissions}}
    end
  end

  defp is_self(context, author) do
    case Permissions.get_current_user(context) do
      nil ->
        false

      current_user ->
        current_user.id == author.user.id
    end
  end
end
