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

            ~i(create_response.data.createUser)
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

            ~i(create_response.data.createUser)
          end)

          inserted_user_id = ~i(inserted_users[0].id)
          inserted_user = ~i(inserted_users[0]) |> handle_user()

          get_all_response = get_users(id: inserted_user_id, access_token: access_token, conn: shared.conn)

          all_users = depaginate(~i(get_all_response.data.users)) |> Enum.map(&handle_user/1)

          expect all_users |> to(match_list [inserted_user])
        end

        it "with name returns list with specific author name only" do
          %{access_token: access_token} = creator()

          users = build_list(3, :user)
          inserted_users = users |> Enum.map(fn (user) ->
            author = build(:author)
            create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

            ~i(create_response.data.createUser)
          end)

          inserted_user = ~i(inserted_users[0]) |> handle_user()

          get_all_response = get_users(name: ~i(inserted_user.author.name), access_token: access_token, conn: shared.conn)

          all_users = depaginate(~i(get_all_response.data.users)) |> Enum.map(&handle_user/1)

          expect all_users |> to(match_list [inserted_user])
        end

        it "with name returns list with specific author name only even if author was deleted" do
          %{access_token: access_token} = creator()

          users = build_list(3, :user)
          inserted_users = users |> Enum.map(fn (user) ->
            author = build(:author)
            create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

            ~i(create_response.data.createUser)
          end)

          inserted_user_author_id = ~i(inserted_users[0].author.id)

          inserted_user = ~i(inserted_users[0]) |> handle_user()

          delete_author(id: inserted_user_author_id, access_token: access_token, conn: shared.conn)

          get_all_response = get_users(name: ~i(inserted_user.author.name), access_token: access_token, conn: shared.conn)

          inserted_user = inserted_user |> Map.put(:author, nil)

          all_users = depaginate(~i(get_all_response.data.users)) |> Enum.map(&handle_user/1)

          expect all_users |> to(match_list [inserted_user])
        end

        it "with email returns list with specific author email only" do
          %{access_token: access_token} = creator()

          users = build_list(3, :user)
          inserted_users = users |> Enum.map(fn (user) ->
            author = build(:author)
            create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

            ~i(create_response.data.createUser)
          end)

          inserted_user = ~i(inserted_users[0]) |> handle_user()

          get_all_response = get_users(email: ~i(inserted_user.author.email), access_token: access_token, conn: shared.conn)

          all_users = depaginate(~i(get_all_response.data.users)) |> Enum.map(&handle_user/1)

          expect all_users |> to(match_list [inserted_user])
        end

        it "with email returns list with specific author email only even if author was deleted" do
          %{access_token: access_token} = creator()

          users = build_list(3, :user)
          inserted_users = users |> Enum.map(fn (user) ->
            author = build(:author)
            create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

            ~i(create_response.data.createUser)
          end)

          inserted_user_author_id = ~i(inserted_users[0].author.id)

          inserted_user = ~i(inserted_users[0]) |> handle_user()

          delete_author(id: inserted_user_author_id, access_token: access_token, conn: shared.conn)

          get_all_response = get_users(email: ~i(inserted_user.author.email), access_token: access_token, conn: shared.conn)

          inserted_user = inserted_user |> Map.put(:author, nil)

          all_users = depaginate(~i(get_all_response.data.users)) |> Enum.map(&handle_user/1)

          expect all_users |> to(match_list [inserted_user])
        end

        it "returns name and email even if author was deleted" do
          %{access_token: access_token} = creator()

          users = build_list(3, :user)
          inserted_users = users |> Enum.map(fn (user) ->
            author = build(:author)
            create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

            ~i(create_response.data.createUser)
          end)

          inserted_user_author_id = ~i(inserted_users[0].author.id)

          inserted_user = ~i(inserted_users[0]) |> handle_user() |> Map.put(:author, nil)

          delete_author(id: inserted_user_author_id, access_token: access_token, conn: shared.conn)

          get_all_response = get_users(access_token: access_token, conn: shared.conn)

          all_users = depaginate(~i(get_all_response.data.users)) |> Enum.map(&handle_user/1)

          expect all_users |> to(have inserted_user)
        end

        [:user, :moderator, :admin]
        |> Enum.each(fn role ->
          it "with #{role} role returns list with specific role only" do
            %{access_token: access_token, user: creatr} = creator()

            other_roles = [:user, :moderator, :admin] |> Enum.filter(fn item -> item != unquote(role) end)
            other_roles |> Enum.each(fn other_role ->
              users = build_list(3, other_role)
              users |> Enum.map(fn (user) ->
                author = build(:author)
                create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)
              end)
            end)

            users = build_list(3, unquote(role))
            inserted_users = users |> Enum.map(fn (user) ->
              author = build(:author)
              create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

              ~i(create_response.data.createUser)
            end)

            inserted_users = if unquote(role) == :admin do
              (inserted_users ++ [creatr]) |> Enum.map(&handle_user/1)
            else
              inserted_users |> Enum.map(&handle_user/1)
            end

            get_all_response = get_users(role: "#{unquote(role)}" |> String.upcase(), access_token: access_token, conn: shared.conn)

            all_users = depaginate(~i(get_all_response.data.users)) |> Enum.map(&handle_user/1)

            expect all_users |> to(match_list inserted_users)
          end
        end)

        it "does not return deleted user" do
          %{access_token: access_token} = creator()

          users = build_list(3, :user)
          inserted_users = users |> Enum.map(fn (user) ->
            author = build(:author)
            create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

            ~i(create_response.data.createUser)
          end)

          inserted_user_id = ~i(inserted_users[0].id)
          inserted_user = ~i(inserted_users[0]) |> handle_user()

          delete_user(id: inserted_user_id, access_token: access_token, conn: shared.conn)

          get_all_response = get_users(access_token: access_token, conn: shared.conn)

          all_users = depaginate(~i(get_all_response.data.users)) |> Enum.map(&handle_user/1)

          expect all_users |> not_to(have inserted_user)
        end

        it "returns deleted user if asked for" do
          %{access_token: access_token} = creator()

          users = build_list(3, :user)
          inserted_users = users |> Enum.map(fn (user) ->
            author = build(:author)
            create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

            ~i(create_response.data.createUser)
          end)

          inserted_user_id = ~i(inserted_users[0].id)
          inserted_user = ~i(inserted_users[0]) |> handle_user()

          delete_user(id: inserted_user_id, access_token: access_token, conn: shared.conn)

          get_all_response = get_users(deleted: true, access_token: access_token, conn: shared.conn)

          all_users = depaginate(~i(get_all_response.data.users)) |> Enum.map(&handle_user/1)

          expect all_users |> to(have inserted_user)
        end
      end

      describe "user" do
        it "with id returns specific user" do
          %{access_token: access_token} = creator()

          users = build_list(3, :user)
          inserted_users = users |> Enum.map(fn (user) ->
            author = build(:author)
            create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

            ~i(create_response.data.createUser)
          end)

          inserted_user_id = ~i(inserted_users[0].id)
          inserted_user = ~i(inserted_users[0]) |> handle_user()

          get_one_response = get_user(id: inserted_user_id, access_token: access_token, conn: shared.conn)

          one_user = ~i(get_one_response.data.user) |> handle_user()

          expect one_user |> to(eq inserted_user)
        end

        it "with name returns specific user by author name" do
          %{access_token: access_token} = creator()

          users = build_list(3, :user)
          inserted_users = users |> Enum.map(fn (user) ->
            author = build(:author)
            create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

            ~i(create_response.data.createUser)
          end)

          inserted_user = ~i(inserted_users[0]) |> handle_user()

          get_one_response = get_user(name: ~i(inserted_user.author.name), access_token: access_token, conn: shared.conn)

          one_user = ~i(get_one_response.data.user) |> handle_user()

          expect one_user |> to(eq inserted_user)
        end

        it "with name returns specific user by deleted author name" do
          %{access_token: access_token} = creator()

          users = build_list(3, :user)
          inserted_users = users |> Enum.map(fn (user) ->
            author = build(:author)
            create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

            ~i(create_response.data.createUser)
          end)

          inserted_user_author_id = ~i(inserted_users[0].author.id)

          inserted_user = ~i(inserted_users[0]) |> handle_user()

          delete_author(id: inserted_user_author_id, access_token: access_token, conn: shared.conn)

          get_one_response = get_user(name: ~i(inserted_user.author.name), access_token: access_token, conn: shared.conn)

          inserted_user = inserted_user |> Map.put(:author, nil)

          one_user = ~i(get_one_response.data.user) |> handle_user()

          expect one_user |> to(eq(inserted_user))
        end

        it "with email returns specific user by author email" do
          %{access_token: access_token} = creator()

          users = build_list(3, :user)
          inserted_users = users |> Enum.map(fn (user) ->
            author = build(:author)
            create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

            ~i(create_response.data.createUser)
          end)

          inserted_user = ~i(inserted_users[0]) |> handle_user()

          get_one_response = get_user(email: ~i(inserted_user.author.email), access_token: access_token, conn: shared.conn)

          one_user = ~i(get_one_response.data.user) |> handle_user()

          expect one_user |> to(eq inserted_user)
        end

        it "with email returns specific user by deleted author email" do
          %{access_token: access_token} = creator()

          users = build_list(3, :user)
          inserted_users = users |> Enum.map(fn (user) ->
            author = build(:author)
            create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

            ~i(create_response.data.createUser)
          end)

          inserted_user_author_id = ~i(inserted_users[0].author.id)

          inserted_user = ~i(inserted_users[0]) |> handle_user()

          delete_author(id: inserted_user_author_id, access_token: access_token, conn: shared.conn)

          get_one_response = get_user(email: ~i(inserted_user.author.email), access_token: access_token, conn: shared.conn)

          inserted_user = inserted_user |> Map.put(:author, nil)

          one_user = ~i(get_one_response.data.user) |> handle_user()

          expect one_user |> to(eq(inserted_user))
        end

        it "without input returns current user from context" do
          users = build_list(3, :user)
          %{access_token: access_token} = creator()

          inserted_users = users |> Enum.map(fn (user) ->
            author = build(:author)
            create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

            ~i(create_response.data.createUser)
          end)

          user = ~i(users[0])
          inserted_user = ~i(inserted_users[0]) |> handle_user()
          author = %{email: ~i(inserted_user.author.email)}

          access_token = auth(user, author, shared.conn)

          get_one_response = get_user(access_token: access_token, conn: shared.conn)
          one_user = ~i(get_one_response.data.user) |> handle_user()

          expect one_user |> to(eq inserted_user)
        end

        it "without input and context returns error" do
          get_one_response = get_user(conn: shared.conn)

          expect ~i(get_one_response.data.user) |> to(be_nil())
          expect ~i(get_one_response.errors) |> not_to(be_nil())
        end

        it "returns name and email even if author was deleted" do
          %{access_token: access_token} = creator()

          users = build_list(3, :user)
          inserted_users = users |> Enum.map(fn (user) ->
            author = build(:author)
            create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

            ~i(create_response.data.createUser)
          end)

          inserted_user_id = ~i(inserted_users[0].id)
          inserted_user_author_id = ~i(inserted_users[0].author.id)

          inserted_user = ~i(inserted_users[0]) |> handle_user() |> Map.put(:author, nil)

          delete_author(id: inserted_user_author_id, access_token: access_token, conn: shared.conn)

          get_one_response = get_user(id: inserted_user_id, access_token: access_token, conn: shared.conn)

          one_user = ~i(get_one_response.data.user) |> handle_user()

          expect one_user |> to(eq(inserted_user))
        end

        it "does not return deleted user" do
          %{access_token: access_token} = creator()

          users = build_list(3, :user)
          inserted_users = users |> Enum.map(fn (user) ->
            author = build(:author)
            create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

            ~i(create_response.data.createUser)
          end)

          inserted_user_id = ~i(inserted_users[0].id)

          delete_user(id: inserted_user_id, access_token: access_token, conn: shared.conn)

          get_one_response = get_user(id: inserted_user_id, access_token: access_token, conn: shared.conn)

          one_user = ~i(get_one_response.data.user)

          expect one_user |> to(be_nil())
        end

        it "returns deleted user if asked for" do
          %{access_token: access_token} = creator()

          users = build_list(3, :user)
          inserted_users = users |> Enum.map(fn (user) ->
            author = build(:author)
            create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

            ~i(create_response.data.createUser)
          end)

          inserted_user_id = ~i(inserted_users[0].id)
          inserted_user = ~i(inserted_users[0]) |> handle_user()

          delete_user(id: inserted_user_id, access_token: access_token, conn: shared.conn)

          get_one_response = get_user(id: inserted_user_id, deleted: true, access_token: access_token, conn: shared.conn)

          one_user = ~i(get_one_response.data.user) |> handle_user()

          expect one_user |> to(eq(inserted_user))
        end
      end
    end
  end
end
