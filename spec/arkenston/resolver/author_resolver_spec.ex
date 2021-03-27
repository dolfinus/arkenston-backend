defmodule Arkenston.Resolver.AuthorResolverSpec do
  import Arkenston.Factories.MainFactory
  alias Arkenston.Subject
  alias Arkenston.Repo
  alias Arkenston.I18n
  import SubjectHelper
  use GraphqlHelper
  use ESpec, async: true
  import Faker.Person.En, only: [first_name: 0, last_name: 0]
  import Indifferent.Sigils

  let :creator do
    user = build(:admin)
    author = build(:author)

    {:ok, result} = Subject.create_author(author)
    {:ok, result} = Subject.create_user(user |> Map.put(:author_id, result.id))

    result = result |> Repo.preload(:author)

    %{user: result, id: result.id, access_token: auth(user, author, shared.conn)}
  end

  let :translation_with_default_locale do
    %{locale: I18n.default_locale() |> String.upcase(), first_name: first_name(), last_name: last_name(), middle_name: first_name()}
  end

  let :translation_with_custom_locale do
    %{locale: "RU", first_name: first_name(), last_name: last_name(), middle_name: first_name()}
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

        it "without locale returns translations for default locale" do
          %{access_token: access_token} = creator()

          authors = Enum.map(1..3, fn _ ->
            default = translation_with_default_locale()
            custom  = translation_with_custom_locale()

            build(:author, translations: [default, custom])
                     |> Map.drop([:first_name, :last_name, :middle_name])
          end)

          authors |> Enum.each(fn (author) ->
            create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)
          end)

          get_all_response = get_authors(access_token: access_token, conn: shared.conn)
          all_authors = depaginate(~i(get_all_response.data.authors))

          authors |> Enum.each(fn author ->
            [default, _] = author.translations

            inserted_author = all_authors |> Enum.find(fn item -> ~i(item.name) == author.name end)

            expect ~i(inserted_author.first_name)  |> to(eq(default.first_name))
            expect ~i(inserted_author.last_name)   |> to(eq(default.last_name))
            expect ~i(inserted_author.middle_name) |> to(eq(default.middle_name))
          end)
        end

        it "with locale returns translations for custom locale" do
          %{access_token: access_token} = creator()

          authors = Enum.map(1..3, fn _ ->
            default = translation_with_default_locale()
            custom  = translation_with_custom_locale()

            build(:author, translations: [default, custom])
                     |> Map.drop([:first_name, :last_name, :middle_name])
          end)

          authors |> Enum.each(fn (author) ->
            create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)
          end)

          get_all_response = get_authors(access_token: access_token, conn: shared.conn, locale: :ru)
          all_authors = depaginate(~i(get_all_response.data.authors))

          authors |> Enum.each(fn author ->
            [_, custom] = author.translations

            inserted_author = all_authors |> Enum.find(fn item -> ~i(item.name) == author.name end)

            expect ~i(inserted_author.first_name)  |> to(eq(custom.first_name))
            expect ~i(inserted_author.last_name)   |> to(eq(custom.last_name))
            expect ~i(inserted_author.middle_name) |> to(eq(custom.middle_name))
          end)
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

        it "without locale returns translations for default locale" do
          %{access_token: access_token} = creator()

          authors = Enum.map(1..3, fn _ ->
            default = translation_with_default_locale()
            custom  = translation_with_custom_locale()

            build(:author, translations: [default, custom])
                     |> Map.drop([:first_name, :last_name, :middle_name])
          end)

          author = authors |> List.first()
          [default, _] = author.translations

          authors |> Enum.each(fn (author) ->
            create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)
          end)

          get_one_response = get_author(name: author.name, access_token: access_token, conn: shared.conn)
          one_author = ~i(get_one_response.data.author)

          expect ~i(one_author.first_name)  |> to(eq(default.first_name))
          expect ~i(one_author.last_name)   |> to(eq(default.last_name))
          expect ~i(one_author.middle_name) |> to(eq(default.middle_name))
        end

        it "with locale returns translations for custom locale" do
          %{access_token: access_token} = creator()

          authors = Enum.map(1..3, fn _ ->
            default = translation_with_default_locale()
            custom  = translation_with_custom_locale()

            build(:author, translations: [default, custom])
                     |> Map.drop([:first_name, :last_name, :middle_name])
          end)

          author = authors |> List.first()
          [_, custom] = author.translations

          authors |> Enum.each(fn (author) ->
            create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)
          end)

          get_one_response = get_author(name: author.name, access_token: access_token, conn: shared.conn, locale: :ru)
          one_author = ~i(get_one_response.data.author)

          expect ~i(one_author.first_name)  |> to(eq(custom.first_name))
          expect ~i(one_author.last_name)   |> to(eq(custom.last_name))
          expect ~i(one_author.middle_name) |> to(eq(custom.middle_name))
        end
      end
    end
  end
end
