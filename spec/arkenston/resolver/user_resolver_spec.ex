defmodule Arkenston.Resolver.UserResolverSpec do
  alias Arkenston.Subject
  alias Arkenston.Resolver.UserResolver
  import Arkenston.Factories.UserFactory
  import SubjectHelper
  use ESpec

  context "resolver", module: :resolver, resolver: true do
    context "with user", user: true do
      describe "all/2" do
        it "without where clause return all users" do
          users = build_list(3, :user)
          inserted_users = users |> Enum.map(fn (user) ->
            {:ok, inserted_user} = user |> Subject.create_user()

            inserted_user
          end) |> Enum.map(&get_user/1)

          {:ok, result} = UserResolver.all()
          all_users = result |> Enum.map(&get_user/1)

          expect all_users |> to(match_list inserted_users)
        end

        it "with id returns list with specific user only" do
          users = build_list(3, :user)
          inserted_users = users |> Enum.map(fn (user) ->
            {:ok, inserted_user} = user |> Subject.create_user()

            inserted_user
          end)

          inserted_user = inserted_users |> Enum.at(0)

          {:ok, result} = UserResolver.all(id: inserted_user.id)
          all_users = result |> Enum.map(&get_user/1)

          inserted_user = inserted_user |> get_user()
          expect all_users |> to(have inserted_user)
        end
      end

      describe "one/2" do
        it "with id returns specific user" do
          users = build_list(3, :user)
          inserted_users = users |> Enum.map(fn (user) ->
            {:ok, inserted_user} = user |> Subject.create_user()

            inserted_user
          end)
          inserted_user = inserted_users |> Enum.at(0)

          {:ok, result} = UserResolver.one(%{id: inserted_user.id})
          one_user = result |> get_user()

          inserted_user = inserted_user |> get_user()

          expect one_user |> to(eq inserted_user)
        end

        it "without id returns current user from context" do
          users = build_list(3, :user)
          inserted_users = users |> Enum.map(fn (user) ->
            {:ok, inserted_user} = user |> Subject.create_user()

            inserted_user
          end)

          inserted_user = inserted_users |> Enum.at(0)

          {:ok, result} = UserResolver.one(%{}, %{context: %{current_user: inserted_user}})

          inserted_user = inserted_user |> get_user()
          one_user = result |> get_user()

          expect one_user |> to(eq inserted_user)
        end
      end
    end
  end
end
