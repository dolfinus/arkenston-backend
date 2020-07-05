defmodule Arkenston.Resolver.UserResolverSpec do
  import Arkenston.Factories.UserFactory
  alias Arkenston.Subject
  import SubjectHelper
  use GraphqlHelper
  use ESpec, async: true
  import Indifferent.Sigils

  let :author do
    user = build(:admin)
    {:ok, result} = Subject.create_user(user)

    %{user: user, id: result.id, access_token: auth(user, shared.conn)}
  end

  context "resolver", module: :resolver, query: true do
    context "user", user: true do
      describe "users" do
        it "without where clause return all users" do
          %{user: creator, access_token: access_token} = author()

          users = build_list(3, :user)
          inserted_users = users |> Enum.map(fn (user) ->
            create_response = create_user(input: prepare_user(user), access_token: access_token, conn: shared.conn)

            ~i(create_response.result)
          end)

          inserted_users = (inserted_users ++ [creator]) |> Enum.map(&handle_user/1)

          get_all_response = get_users(access_token: access_token, conn: shared.conn)

          all_users = ~i(get_all_response.data.users) |> Enum.map(&handle_user/1)

          expect all_users |> to(match_list inserted_users)
        end

        it "with id returns list with specific user only" do
          %{access_token: access_token} = author()

          users = build_list(3, :user)
          inserted_users = users |> Enum.map(fn (user) ->
            create_response = create_user(input: prepare_user(user), access_token: access_token, conn: shared.conn)

            ~i(create_response.result)
          end)

          inserted_user_id = ~i(inserted_users[0].id)
          inserted_user = ~i(inserted_users[0]) |> handle_user()

          get_all_response = get_users(id: inserted_user_id, access_token: access_token, conn: shared.conn)

          all_users = ~i(get_all_response.data.users) |> Enum.map(&handle_user/1)

          expect all_users |> to(match_list [inserted_user])
        end

        it "does not return deleted user" do
          %{access_token: access_token} = author()

          users = build_list(3, :user)
          inserted_users = users |> Enum.map(fn (user) ->
            create_response = create_user(input: prepare_user(user), access_token: access_token, conn: shared.conn)

            ~i(create_response.result)
          end)

          inserted_user_id = ~i(inserted_users[0].id)
          inserted_user = ~i(inserted_users[0]) |> handle_user()

          delete_user(id: inserted_user_id, access_token: access_token, conn: shared.conn)

          get_all_response = get_users(access_token: access_token, conn: shared.conn)

          all_users = ~i(get_all_response.data.users) |> Enum.map(&handle_user/1)

          expect all_users |> not_to(have inserted_user)
        end
      end

      describe "user" do
        it "with id returns specific user" do
          %{access_token: access_token} = author()

          users = build_list(3, :user)
          inserted_users = users |> Enum.map(fn (user) ->
            create_response = create_user(input: prepare_user(user), access_token: access_token, conn: shared.conn)

            ~i(create_response.result)
          end)

          inserted_user_id = ~i(inserted_users[0].id)
          inserted_user = ~i(inserted_users[0]) |> handle_user()

          get_one_response = get_user(id: inserted_user_id, access_token: access_token, conn: shared.conn)

          one_user = ~i(get_one_response.data.user) |> handle_user()

          expect one_user |> to(eq inserted_user)
        end

        it "without id returns current user from context" do
          users = build_list(3, :user)
          %{access_token: access_token} = author()

          inserted_users = users |> Enum.map(fn (user) ->
            create_response = create_user(input: prepare_user(user), access_token: access_token, conn: shared.conn)

            ~i(create_response.result)
          end)

          user = ~i(users[0])
          inserted_user = ~i(inserted_users[0]) |> handle_user()

          access_token = auth(user, shared.conn)

          get_one_response = get_user(access_token: access_token, conn: shared.conn)
          one_user = ~i(get_one_response.data.user) |> handle_user()

          expect one_user |> to(eq inserted_user)
        end

        it "without id and context returns error" do
          get_one_response = get_user(conn: shared.conn)

          expect ~i(get_one_response.errors) |> not_to(be_nil())
        end

        it "does not return deleted user" do
          %{access_token: access_token} = author()

          users = build_list(3, :user)
          inserted_users = users |> Enum.map(fn (user) ->
            create_response = create_user(input: prepare_user(user), access_token: access_token, conn: shared.conn)

            ~i(create_response.result)
          end)

          inserted_user_id = ~i(inserted_users[0].id)

          delete_user(id: inserted_user_id, access_token: access_token, conn: shared.conn)

          get_one_response = get_user(id: inserted_user_id, access_token: access_token, conn: shared.conn)

          one_user = ~i(get_one_response.data.user)

          expect one_user |> to(be_nil())
        end
      end
    end
  end
end
