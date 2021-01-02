defmodule Arkenston.Resolver.AuthorResolverSpec do
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
    context "subject", subject: true, author: true do
      describe "authors" do
        it "without where clause return authors list with pagination" do
          %{user: creator, access_token: access_token} = creator()

          authors = build_list(3, :author)
          inserted_authors = authors |> Enum.map(fn (author) ->
            create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

            ~i(create_response.data.createAuthor)
          end)

          inserted_authors = (inserted_authors ++ [creator.author]) |> Enum.map(&handle_author/1)

          get_all_response = get_authors(access_token: access_token, conn: shared.conn)

          all_authors = depaginate(~i(get_all_response.data.authors)) |> Enum.map(&handle_author/1)
          expect all_authors |> to(match_list inserted_authors)
        end

        it "with id returns list with specific author only" do
          %{access_token: access_token} = creator()

          authors = build_list(3, :author)
          inserted_authors = authors |> Enum.map(fn (author) ->
            create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

            ~i(create_response.data.createAuthor)
          end)

          inserted_author_id = ~i(inserted_authors[0].id)
          inserted_author = ~i(inserted_authors[0]) |> handle_author()

          get_all_response = get_authors(id: inserted_author_id, access_token: access_token, conn: shared.conn)

          all_authors = depaginate(~i(get_all_response.data.authors)) |> Enum.map(&handle_author/1)

          expect all_authors |> to(match_list [inserted_author])
        end

        it "with name returns list with specific author only" do
          %{access_token: access_token} = creator()

          authors = build_list(3, :author)
          inserted_authors = authors |> Enum.map(fn (author) ->
            create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

            ~i(create_response.data.createAuthor)
          end)

          inserted_author = ~i(inserted_authors[0]) |> handle_author()

          get_all_response = get_authors(name: ~i(inserted_author.name), access_token: access_token, conn: shared.conn)

          all_authors = depaginate(~i(get_all_response.data.authors)) |> Enum.map(&handle_author/1)

          expect all_authors |> to(match_list [inserted_author])
        end

        it "with email returns list with specific author only" do
          %{access_token: access_token} = creator()

          authors = build_list(3, :author)
          inserted_authors = authors |> Enum.map(fn (author) ->
            create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

            ~i(create_response.data.createAuthor)
          end)

          inserted_author = ~i(inserted_authors[0]) |> handle_author()

          get_all_response = get_authors(email: ~i(inserted_author.email), access_token: access_token, conn: shared.conn)

          all_authors = depaginate(~i(get_all_response.data.authors)) |> Enum.map(&handle_author/1)

          expect all_authors |> to(match_list [inserted_author])
        end

        it "does not return deleted author" do
          %{access_token: access_token} = creator()

          authors = build_list(3, :author)
          inserted_authors = authors |> Enum.map(fn (author) ->
            create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

            ~i(create_response.data.createAuthor)
          end)

          inserted_author_id = ~i(inserted_authors[0].id)
          inserted_author = ~i(inserted_authors[0]) |> handle_author()

          delete_author(id: inserted_author_id, access_token: access_token, conn: shared.conn)

          get_all_response = get_authors(access_token: access_token, conn: shared.conn)

          all_authors = depaginate(~i(get_all_response.data.authors)) |> Enum.map(&handle_author/1)

          expect all_authors |> not_to(have inserted_author)
        end

        it "returns deleted author if asked for" do
          %{access_token: access_token} = creator()

          authors = build_list(3, :author)
          inserted_authors = authors |> Enum.map(fn (author) ->
            create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

            ~i(create_response.data.createAuthor)
          end)

          inserted_author_id = ~i(inserted_authors[0].id)
          inserted_author = ~i(inserted_authors[0]) |> handle_author()

          delete_author(id: inserted_author_id, access_token: access_token, conn: shared.conn)

          get_all_response = get_authors(deleted: true, access_token: access_token, conn: shared.conn)

          all_authors = depaginate(~i(get_all_response.data.authors)) |> Enum.map(&handle_author/1)

          expect all_authors |> to(have inserted_author)
        end
      end

      describe "author" do
        it "with id returns specific author" do
          %{access_token: access_token} = creator()

          authors = build_list(3, :author)
          inserted_authors = authors |> Enum.map(fn (author) ->
            create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

            ~i(create_response.data.createAuthor)
          end)

          inserted_author_id = ~i(inserted_authors[0].id)
          inserted_author = ~i(inserted_authors[0]) |> handle_author()

          get_one_response = get_author(id: inserted_author_id, access_token: access_token, conn: shared.conn)

          one_author = ~i(get_one_response.data.author) |> handle_author()

          expect one_author |> to(eq inserted_author)
        end

        it "with name returns specific author" do
          %{access_token: access_token} = creator()

          authors = build_list(3, :author)
          inserted_authors = authors |> Enum.map(fn (author) ->
            create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

            ~i(create_response.data.createAuthor)
          end)

          inserted_author = ~i(inserted_authors[0]) |> handle_author()

          get_one_response = get_author(name: ~i(inserted_author.name), access_token: access_token, conn: shared.conn)

          one_author = ~i(get_one_response.data.author) |> handle_author()

          expect one_author |> to(eq inserted_author)
        end

        it "with email returns specific author" do
          %{access_token: access_token} = creator()

          authors = build_list(3, :author)
          inserted_authors = authors |> Enum.map(fn (author) ->
            create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

            ~i(create_response.data.createAuthor)
          end)

          inserted_author = ~i(inserted_authors[0]) |> handle_author()

          get_one_response = get_author(email: ~i(inserted_author.email), access_token: access_token, conn: shared.conn)

          one_author = ~i(get_one_response.data.author) |> handle_author()

          expect one_author |> to(eq inserted_author)
        end

        it "without input returns current author from context" do
          %{access_token: access_token} = creator()

          users = build_list(3, :user)
          inserted_authors = users |> Enum.map(fn (user) ->
            author = build(:author)
            create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)
            create_user(input: prepare_user(user), author: %{id: ~i(create_response.data.createAuthor.id)}, access_token: access_token, conn: shared.conn)

            ~i(create_response.data.createAuthor)
          end)

          user = ~i(users[0])
          inserted_author = ~i(inserted_authors[0]) |> handle_author()

          access_token = auth(user, inserted_author, shared.conn)

          get_one_response = get_author(access_token: access_token, conn: shared.conn)

          one_author = ~i(get_one_response.data.author) |> handle_author()

          expect one_author |> to(eq inserted_author)
        end

        it "without input and context returns error" do
          get_one_response = get_author(conn: shared.conn)

          expect ~i(get_one_response.data.author) |> to(be_nil())
          expect ~i(get_one_response.errors) |> not_to(be_nil())
        end

        it "does not return deleted author" do
          %{access_token: access_token} = creator()

          authors = build_list(3, :author)
          inserted_authors = authors |> Enum.map(fn (author) ->
            create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

            ~i(create_response.data.createAuthor)
          end)

          inserted_author_id = ~i(inserted_authors[0].id)

          delete_author(id: inserted_author_id, access_token: access_token, conn: shared.conn)

          get_one_response = get_author(id: inserted_author_id, access_token: access_token, conn: shared.conn)

          one_author = ~i(get_one_response.data.author)

          expect one_author |> to(be_nil())
        end

        it "returns deleted author if asked for" do
          %{access_token: access_token} = creator()

          authors = build_list(3, :author)
          inserted_authors = authors |> Enum.map(fn (author) ->
            create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

            ~i(create_response.data.createAuthor)
          end)

          inserted_author_id = ~i(inserted_authors[0].id)
          inserted_author = ~i(inserted_authors[0]) |> handle_author()

          delete_author(id: inserted_author_id, access_token: access_token, conn: shared.conn)

          get_one_response = get_author(id: inserted_author_id, deleted: true, access_token: access_token, conn: shared.conn)

          one_author = ~i(get_one_response.data.author) |> handle_author()

          expect one_author |> to(eq(inserted_author))
        end
      end
    end
  end
end
