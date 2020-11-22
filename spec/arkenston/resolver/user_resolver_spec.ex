defmodule Arkenston.Resolver.UserResolverSpec do
  import Arkenston.Factories.MainFactory
  alias Arkenston.Subject
  alias Arkenston.Repo
  import SubjectHelper
  use GraphqlHelper
  use ESpec, async: true
  import Indifferent.Sigils

  let :creator do
    user = build(:admin)
    author = build(:author)

    {:ok, result} = Subject.create_author(author)
    {:ok, result} = Subject.create_user(user |> Map.put(:author_id, result.id))

    result = result |> Repo.preload(:author)

    %{user: result, id: result.id, access_token: auth(user, author, shared.conn)}
  end

  context "resolver", module: :resolver, query: true do
    context "subject", subject: true, user: true do
      describe "users" do
        it "without where clause return users list with pagination" do
          %{user: creator, access_token: access_token} = creator()

          users = build_list(3, :user)
          inserted_users = users |> Enum.map(fn (user) ->
            author = build(:author)
            create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

            ~i(create_response.result)
          end)

          inserted_users = (inserted_users ++ [creator]) |> Enum.map(&handle_user/1)

          get_all_response = get_users(access_token: access_token, conn: shared.conn)

          all_users = depaginate(~i(get_all_response.data.users)) |> Enum.map(&handle_user/1)
          expect all_users |> to(match_list inserted_users)
        end

        it "with id returns list with specific user only" do
          %{access_token: access_token} = creator()

          users = build_list(3, :user)
          inserted_users = users |> Enum.map(fn (user) ->
            author = build(:author)
            create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

            ~i(create_response.result)
          end)

          inserted_user_id = ~i(inserted_users[0].id)
          inserted_user = ~i(inserted_users[0]) |> handle_user()

          get_all_response = get_users(id: inserted_user_id, access_token: access_token, conn: shared.conn)

          all_users = depaginate(~i(get_all_response.data.users)) |> Enum.map(&handle_user/1)

          expect all_users |> to(match_list [inserted_user])
        end

        it "does not return deleted user" do
          %{access_token: access_token} = creator()

          users = build_list(3, :user)
          inserted_users = users |> Enum.map(fn (user) ->
            author = build(:author)
            create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

            ~i(create_response.result)
          end)

          inserted_user_id = ~i(inserted_users[0].id)
          inserted_user = ~i(inserted_users[0]) |> handle_user()

          delete_user(id: inserted_user_id, access_token: access_token, conn: shared.conn)

          get_all_response = get_users(access_token: access_token, conn: shared.conn)

          all_users = depaginate(~i(get_all_response.data.users)) |> Enum.map(&handle_user/1)

          expect all_users |> not_to(have inserted_user)
        end
      end

      describe "user" do
        it "with id returns specific user" do
          %{access_token: access_token} = creator()

          users = build_list(3, :user)
          inserted_users = users |> Enum.map(fn (user) ->
            author = build(:author)
            create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

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
          %{access_token: access_token} = creator()

          inserted_users = users |> Enum.map(fn (user) ->
            author = build(:author)
            create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

            ~i(create_response.result)
          end)

          user = ~i(users[0])
          inserted_user = ~i(inserted_users[0]) |> handle_user()
          author = %{email: ~i(inserted_user.author.email)}

          access_token = auth(user, author, shared.conn)

          get_one_response = get_user(access_token: access_token, conn: shared.conn)
          one_user = ~i(get_one_response.data.user) |> handle_user()

          expect one_user |> to(eq inserted_user)
        end

        it "without id and context returns error" do
          get_one_response = get_user(conn: shared.conn)

          expect ~i(get_one_response.errors) |> not_to(be_nil())
        end

        it "does not return deleted user" do
          %{access_token: access_token} = creator()

          users = build_list(3, :user)
          inserted_users = users |> Enum.map(fn (user) ->
            author = build(:author)
            create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

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
