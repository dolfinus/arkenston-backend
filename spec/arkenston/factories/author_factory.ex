defmodule Arkenston.Factories.AuthorFactory do
  defmacro __using__(_args) do
    quote do
      import Faker.Internet, only: [slug: 0, email: 0]
      import Faker.Person.En, only: [first_name: 0, last_name: 0]

      def author_factory do
        %{
          name: slug(),
          email: email(),
          first_name: first_name(),
          middle_name: first_name(),
          last_name: last_name()
        }
      end
    end
  end
end
