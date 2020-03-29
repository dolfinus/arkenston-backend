defmodule ArkenstonWeb.Schema.Query do
  defmacro __using__(_opts) do
    quote do

      query do
        field :users, list_of(:user) do
          arg(:id, :id)
          arg(:name, :string)
          arg(:email, :string)
          arg(:role, :integer)
          arg(:deleted, :boolean)
          resolve(&Arkenston.Subject.UserResolver.all/2)
        end

        field :user, :user do
          arg(:id, :id)
          arg(:name, :string)
          arg(:email, :string)
          arg(:role, :integer)
          arg(:deleted, :boolean)
          resolve(&Arkenston.Subject.UserResolver.find/2)
        end
      end
    end
  end
end
