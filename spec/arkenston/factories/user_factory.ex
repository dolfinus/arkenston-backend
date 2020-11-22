defmodule Arkenston.Factories.UserFactory do
  defmacro __using__(_args) do
    quote do
      import Faker.String, only: [base64: 1]

      def user_factory do
        %{
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
  end
end
