defmodule ArkenstonWeb.Schema.Mutation do
  defmacro __using__(_opts) do
    quote do
      mutation do
        field :login, :session do
          arg(:email, non_null(:string))
          arg(:password, non_null(:string))

          resolve(&Arkenston.Subject.UserResolver.login/2)
        end

        field :logout, :user do
          arg(:id, non_null(:id))
          resolve(&Arkenston.Subject.UserResolver.logout/2)
        end
      end
    end
  end
end
