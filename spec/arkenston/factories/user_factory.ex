defmodule Arkenston.Factories.UserFactory do
  use ExMachina
  import Faker.Internet, only: [email: 0, slug: 0]
  import Faker.String, only: [base64: 1]

  def user_factory do
    %{
      name: slug(),
      email: email(),
      password: base64(6),
      role: :user
    }
  end

  def moderator_factory do
    %{user_factory() | role: :moderator}
  end

  def admin_factory do
    %{user_factory() | role: :admin}
  end
end
