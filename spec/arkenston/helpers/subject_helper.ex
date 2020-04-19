defmodule SubjectHelper do
  alias Arkenston.Subject.User

  @check_attrs [:name, :email, :role]
  @all_attrs [:name, :email, :password_hash, :role]

  def get_user(user) do
    user |> Map.take(@all_attrs)
  end

  def check_user(user1, user2) do
    (Map.take(user1, @check_attrs) == Map.take(user2, @check_attrs)) && User.check_password(user1, user2.password)
  end
end
