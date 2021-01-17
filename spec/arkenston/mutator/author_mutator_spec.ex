defmodule Arkenston.Mutator.AuthorMutatorSpec do
  import Arkenston.Factories.MainFactory
  alias Arkenston.Subject
  alias Arkenston.Repo
  alias Arkenston.I18n
  import Arkenston.Helper.UUID
  import SubjectHelper
  use GraphqlHelper
  import Faker.Internet, only: [slug: 0, email: 0]
  import Faker.Person.En, only: [first_name: 0, last_name: 0]
  import Faker.Lorem, only: [word: 0, sentence: 0, characters: 1]
  use ESpec, async: true
  import Indifferent.Sigils

  let :valid_attrs do
    %{name: slug(), email: email(), first_name: first_name(), last_name: last_name(), middle_name: first_name()}
  end

  let :translation do
    %{first_name: first_name(), last_name: last_name(), middle_name: first_name()}
  end

  let :translation_with_default_locale do
    %{locale: I18n.default_locale() |> String.upcase(), first_name: first_name(), last_name: last_name(), middle_name: first_name()}
  end

  let :translation_with_custom_locale do
    %{locale: "RU", first_name: first_name(), last_name: last_name(), middle_name: first_name()}
  end

  let :translation_with_unknown_locale do
    %{locale: characters(2) |> to_string() |> String.upcase(), first_name: first_name(), last_name: last_name(), middle_name: first_name()}
  end

  let :creator_user do
    user = build(:user)
    author = build(:author)

    {:ok, result} = Subject.create_author(author)
    {:ok, result} = Subject.create_user(user |> Map.put(:author_id, result.id))

    result = result |> Repo.preload(:author)

    %{user: user, author: user, id: result.id, access_token: auth(user, author, shared.conn)}
  end

  let :creator_moderator do
    user = build(:moderator)
    author = build(:author)

    {:ok, result} = Subject.create_author(author)
    {:ok, result} = Subject.create_user(user |> Map.put(:author_id, result.id))

    result = result |> Repo.preload(:author)

    %{user: user, author: user, id: result.id, access_token: auth(user, author, shared.conn)}
  end

  let :creator_admin do
    user = build(:admin)
    author = build(:author)

    {:ok, result} = Subject.create_author(author)
    {:ok, result} = Subject.create_user(user |> Map.put(:author_id, result.id))

    result = result |> Repo.preload(:author)

    %{user: user, author: user, id: result.id, access_token: auth(user, author, shared.conn)}
  end

  let :creator_anonymous do
    nil
  end

  let :creator do
    creator_admin()
  end

  context "mutator", module: :mutator, mutation: true do
    context "author", author: true do
      describe "createAuthor" do
        it "returns created author for valid attrs", validation: true, valid: true do
          author = build(:author)

          %{access_token: access_token} = creator()
          create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

          expect ~i(create_response.errors) |> to(be_nil())
          assert check_author(~i(create_response.data.createAuthor), prepare_author(author))
        end

        [
          en: "Author with the same name %{name} is already exist",
          ru: "Автор с аналогичным именем %{name} уже существует"
        ] |> Enum.each(fn {locale, msg} ->
          it "returns error for already used name (#{locale})", validation: true, valid: false, locale: locale do
            %{access_token: access_token} = creator()

            existing_author = build(:author)
            create_author(input: prepare_author(existing_author), access_token: access_token, conn: shared.conn)

            invalid_author = build(:author, name: existing_author.name |> String.upcase())

            create_response = create_author(input: prepare_author(invalid_author), access_token: access_token, conn: shared.conn, locale: unquote(locale))

            expect ~i(create_response.errors) |> not_to(be_empty())
            expect ~i(create_response.errors[0].operation) |> to(eq("createAuthor"))
            expect ~i(create_response.errors[0].entity) |> to(eq("author"))
            expect ~i(create_response.errors[0].code) |> to(eq("unique"))
            expect ~i(create_response.errors[0].field) |> to(eq("name"))
            expect ~i(create_response.errors[0].message) |> to(eq(unquote(msg) |> String.replace("%{name}", String.downcase(invalid_author.name))))
          end
        end)

        [
          en: "Author with the same email %{email} is already exist",
          ru: "Автор с аналогичным email %{email} уже существует"
        ] |> Enum.each(fn {locale, msg} ->
          it "returns error for already used email (#{locale})", validation: true, valid: false, locale: locale do
            %{access_token: access_token} = creator()

            existing_author = build(:author)
            create_author(input: prepare_author(existing_author), access_token: access_token, conn: shared.conn)

            invalid_author = build(:author, email: existing_author.email |> String.upcase())

            create_response = create_author(input: prepare_author(invalid_author), access_token: access_token, conn: shared.conn, locale: unquote(locale))

            expect ~i(create_response.errors) |> not_to(be_empty())
            expect ~i(create_response.errors[0].operation) |> to(eq("createAuthor"))
            expect ~i(create_response.errors[0].entity) |> to(eq("author"))
            expect ~i(create_response.errors[0].code) |> to(eq("unique"))
            expect ~i(create_response.errors[0].field) |> to(eq("email"))
            expect ~i(create_response.errors[0].message) |> to(eq(unquote(msg) |> String.replace("%{email}", String.downcase(invalid_author.email))))
          end
        end)

        it "returns error for empty name", validation: true, valid: false do
          author = build(:author)

          create_response = create_author(input: prepare_author(author) |> Map.drop([:name]), conn: shared.conn)
          expect ~i(create_response.errors) |> not_to(be_empty())
          expect ~i(create_response.errors[0].operation) |> to(be_nil())

          create_response = create_author(input: prepare_author(author) |> Map.put(:name, nil), conn: shared.conn)

          expect ~i(create_response.errors) |> not_to(be_empty())
          expect ~i(create_response.errors[0].operation) |> to(be_nil())
        end

        [
          en: "Author name should be at least 3 characters long",
          ru: "Длина имени автора должна составлять минимум 3 символа"
        ] |> Enum.each(fn {locale, msg} ->
          it "returns error for too short name (#{locale})", validation: true, valid: false, locale: locale do
            %{access_token: access_token} = creator()

            author = build(:author)
            create_response = create_author(input: prepare_author(author) |> Map.put(:name, characters(1) |> to_string()), access_token: access_token, conn: shared.conn, locale: unquote(locale))

            expect ~i(create_response.errors) |> not_to(be_empty())
            expect ~i(create_response.errors[0].operation) |> to(eq("createAuthor"))
            expect ~i(create_response.errors[0].entity) |> to(eq("author"))
            expect ~i(create_response.errors[0].code) |> to(eq("min"))
            expect ~i(create_response.errors[0].field) |> to(eq("name"))
            expect ~i(create_response.errors[0].message) |> to(eq(unquote(msg)))

            create_response = create_author(input: prepare_author(author) |> Map.put(:name, characters(2) |> to_string()), access_token: access_token, conn: shared.conn, locale: unquote(locale))

            expect ~i(create_response.errors) |> not_to(be_empty())
            expect ~i(create_response.errors[0].operation) |> to(eq("createAuthor"))
            expect ~i(create_response.errors[0].entity) |> to(eq("author"))
            expect ~i(create_response.errors[0].code) |> to(eq("min"))
            expect ~i(create_response.errors[0].field) |> to(eq("name"))
            expect ~i(create_response.errors[0].message) |> to(eq(unquote(msg)))
          end
        end)

        [
          en: "Author name %{name} has invalid format",
          ru: "Имя автора %{name} не соответствует формату"
        ] |> Enum.each(fn {locale, msg} ->
          it "returns error for invalid name (#{locale})", validation: true, valid: false, locale: locale do
            %{access_token: access_token} = creator()

            author = build(:author, name: "оШиБкА")
            create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn, locale: unquote(locale))

            expect ~i(create_response.errors) |> not_to(be_empty())
            expect ~i(create_response.errors[0].operation) |> to(eq("createAuthor"))
            expect ~i(create_response.errors[0].entity) |> to(eq("author"))
            expect ~i(create_response.errors[0].code) |> to(eq("format"))
            expect ~i(create_response.errors[0].field) |> to(eq("name"))
            expect ~i(create_response.errors[0].message) |> to(eq(unquote(msg) |> String.replace("%{name}", String.downcase(author.name))))
          end
        end)

        it "returns success without email", validation: true, valid: true do
          %{access_token: access_token} = creator()

          author = build(:author)
          create_response = create_author(input: prepare_author(author) |> Map.drop([:email]), access_token: access_token, conn: shared.conn)

          expect ~i(create_response.errors) |> to(be_nil())
          assert check_author(~i(create_response.data.createAuthor), prepare_author(author) |> Map.put(:email, nil))

          author = build(:author)
          create_response = create_author(input: prepare_author(author) |> Map.put(:email, nil), access_token: access_token, conn: shared.conn)
          expect ~i(create_response.errors) |> to(be_nil())
          assert check_author(~i(create_response.data.createAuthor), prepare_author(author) |> Map.put(:email, nil))

          author = build(:author)
          create_response = create_author(input: prepare_author(author) |> Map.put(:email, ""), access_token: access_token, conn: shared.conn)
          expect ~i(create_response.errors) |> to(be_nil())
          assert check_author(~i(create_response.data.createAuthor), prepare_author(author) |> Map.put(:email, nil))
        end

        [
          en: "Author email %{email} has invalid format",
          ru: "Email автора %{email} не соответствует формату"
        ] |> Enum.each(fn {locale, msg} ->
          it "returns error for invalid email (#{locale})", validation: true, valid: false, locale: locale do
            %{access_token: access_token} = creator()

            author = build(:author, email: word() |> String.upcase())
            create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn, locale: unquote(locale))

            expect ~i(create_response.errors) |> not_to(be_empty())
            expect ~i(create_response.errors[0].operation) |> to(eq("createAuthor"))
            expect ~i(create_response.errors[0].entity) |> to(eq("author"))
            expect ~i(create_response.errors[0].code) |> to(eq("format"))
            expect ~i(create_response.errors[0].field) |> to(eq("email"))
            expect ~i(create_response.errors[0].message) |> to(eq(unquote(msg) |> String.replace("%{email}", String.downcase(author.email))))
          end
        end)

        it "accepts note for revision", audit: true do
          note = sentence()
          author = build(:author)

          %{access_token: access_token} = creator()
          create_response = create_author(input: prepare_author(author) |> Map.merge(%{note: note}), access_token: access_token, conn: shared.conn)
          expect ~i(create_response.data.createAuthor.note) |> to(eq(note))
        end

        it "sets revision version to 1", audit: true do
          author = build(:author)

          %{access_token: access_token} = creator()
          create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

          expect ~i(create_response.data.createAuthor.version) |> to(eq(1))
        end

        it "sets created_by to non-nil if context is not empty", audit: true do
          author = build(:author)

          %{access_token: access_token, id: creator_id} = creator()
          create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

          expect ~i(create_response.data.createAuthor.created_by.id) |> to(eq(creator_id))
        end

        [
          en: "Not enough permissions to create author",
          ru: "Недостаточно прав для создания автора"
        ] |> Enum.each(fn {locale, msg} ->
          it "returns error for anonymous user (#{locale})", validation: true, valid: false, locale: locale do
            author = build(:author)

            create_response = create_author(input: prepare_author(author), conn: shared.conn, locale: unquote(locale))

            expect ~i(create_response.errors) |> not_to(be_empty())
            expect ~i(create_response.errors[0].operation) |> to(eq("createAuthor"))
            expect ~i(create_response.errors[0].entity) |> to(eq("author"))
            expect ~i(create_response.errors[0].code) |> to(eq("permissions"))
            expect ~i(create_response.errors[0].field) |> to(be_nil())
            expect ~i(create_response.errors[0].message) |> to(eq(unquote(msg)))
          end
        end)

        it "sets created_by to nil if context is empty", audit: true, role: :anonymous do
          user = build(:user)
          author = build(:author)

          create_response = create_user(input: prepare_user(user), author: prepare_author(author), conn: shared.conn)

          expect ~i(create_response.data.createAuthor.created_by) |> to(be_nil())
        end

        it "saves translated fields", audit: true do
          author = build(:author, translation())

          %{access_token: access_token} = creator()
          create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

          expect ~i(create_response.data.createAuthor.first_name)  |> to(eq(translation().first_name))
          expect ~i(create_response.data.createAuthor.last_name)   |> to(eq(translation().last_name))
          expect ~i(create_response.data.createAuthor.middle_name) |> to(eq(translation().middle_name))

          translations = ~i(create_response.data.createAuthor.translations)

          default_translation = translations |> Enum.filter(fn item -> ~i(item.locale) |> String.downcase() == I18n.default_locale() end) |> Enum.at(0)

          expect ~i(default_translation.first_name)  |> to(eq(translation().first_name))
          expect ~i(default_translation.last_name)   |> to(eq(translation().last_name))
          expect ~i(default_translation.middle_name) |> to(eq(translation().middle_name))
        end

        it "saves translations list", audit: true do
          default = translation_with_default_locale()
          custom  = translation_with_custom_locale()

          author = build(:author, translations: [default, custom])
                   |> Map.drop([:first_name, :last_name, :middle_name])

          %{access_token: access_token} = creator()
          create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

          expect ~i(create_response.data.createAuthor.first_name)  |> to(eq(default.first_name))
          expect ~i(create_response.data.createAuthor.last_name)   |> to(eq(default.last_name))
          expect ~i(create_response.data.createAuthor.middle_name) |> to(eq(default.middle_name))

          translations = ~i(create_response.data.createAuthor.translations)

          default_translation = translations |> Enum.filter(fn item -> ~i(item.locale) == default.locale end) |> Enum.at(0)
          custom_translation  = translations |> Enum.filter(fn item -> ~i(item.locale) == custom.locale  end) |> Enum.at(0)

          expect ~i(default_translation.first_name)  |> to(eq(default.first_name))
          expect ~i(default_translation.last_name)   |> to(eq(default.last_name))
          expect ~i(default_translation.middle_name) |> to(eq(default.middle_name))

          expect ~i(custom_translation.first_name)  |> to(eq(custom.first_name))
          expect ~i(custom_translation.last_name)   |> to(eq(custom.last_name))
          expect ~i(custom_translation.middle_name) |> to(eq(custom.middle_name))
        end

        it "return error for unknown locale", audit: true do
          author = build(:author, translations: [translation_with_unknown_locale()])
                   |> Map.drop([:first_name, :last_name, :middle_name])

          %{access_token: access_token} = creator()
          create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

          expect ~i(create_response.errors) |> not_to(be_empty())
          expect ~i(create_response.errors[0].operation) |> to(be_nil())
        end

        it "sets created_at", audit: true do
          author = build(:author)

          %{access_token: access_token} = creator()
          create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

          expect ~i(create_response.data.createAuthor.created_at) |> not_to(be_nil())
        end

        [:user, :moderator, :admin]
        |> Enum.each(fn role ->
            it "allows to create new author by #{role}", permission: true, allow: true, role: role do
              author = build(:author)

              %{access_token: access_token} = unquote(:"creator_#{role}")()
              create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

              expect ~i(create_response.errors) |> to(be_nil())
            end
        end)
      end

      describe "updateAuthor" do
        it "returns success for valid id", validation: true, valid: true do
          author = build(:author)

          %{access_token: access_token} = creator()
          create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

          update_response = update_author(id: ~i(create_response.data.createAuthor.id), input: prepare_author(valid_attrs()), access_token: access_token, conn: shared.conn)

          expect ~i(update_response.errors) |> to(be_nil())

          expected_author = prepare_author(author) |> Map.merge(valid_attrs())
          assert check_author(~i(update_response.data.updateAuthor), expected_author)
        end

        it "returns success for valid name", validation: true, valid: true do
          author = build(:author)

          %{access_token: access_token} = creator()
          create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

          update_response = update_author(id: ~i(create_response.data.createAuthor.id), input: prepare_author(valid_attrs()), access_token: access_token, conn: shared.conn)

          expect ~i(update_response.errors) |> to(be_nil())

          expected_author = prepare_author(author) |> Map.merge(valid_attrs())
          assert check_author(~i(update_response.data.updateAuthor), expected_author)
        end

        it "returns success for valid email", validation: true, valid: true do
          author = build(:author)

          %{access_token: access_token} = creator()
          create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

          update_response = update_author(email: author.email, input: prepare_author(valid_attrs()), access_token: access_token, conn: shared.conn)

          expect ~i(update_response.errors) |> to(be_nil())

          expected_author = prepare_author(author) |> Map.merge(valid_attrs())
          assert check_author(~i(update_response.data.updateAuthor), expected_author)
        end

        it "returns success for current user", validation: true, valid: true do
          user = build(:user)
          author = build(:author)

          %{access_token: access_token} = creator()
          create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

          access_token = auth(user, author, shared.conn)
          update_response = update_author(input: prepare_author(valid_attrs()), access_token: access_token, conn: shared.conn)

          expect ~i(update_response.errors) |> to(be_nil())
          expected_author = prepare_author(author) |> Map.merge(valid_attrs())
          assert check_author(~i(update_response.data.updateAuthor), expected_author)
        end

        [
          en: "Cannot find author with specified id",
          ru: "Автор с указанным id не найден"
        ] |> Enum.each(fn {locale, msg} ->
          it "returns error for unknown id (#{locale})", validation: true, valid: false, locale: locale do
            %{access_token: access_token} = creator()
            update_response = update_author(id: domain_uuid(:author), input: prepare_author(valid_attrs()), access_token: access_token, conn: shared.conn, locale: unquote(locale))

            expect ~i(update_response.errors) |> not_to(be_empty())
            expect ~i(update_response.errors[0].operation) |> to(eq("updateAuthor"))
            expect ~i(update_response.errors[0].entity) |> to(eq("author"))
            expect ~i(update_response.errors[0].code) |> to(eq("missing"))
            expect ~i(update_response.errors[0].field) |> to(eq("id"))
            expect ~i(update_response.errors[0].message) |> to(eq(unquote(msg)))
          end
        end)

        [
          en: "Cannot find author with specified name",
          ru: "Автор с указанным именем не найден"
        ] |> Enum.each(fn {locale, msg} ->
          it "returns error for unknown name (#{locale})", validation: true, valid: true, locale: locale do
            author = build(:author)

            %{access_token: access_token} = creator()

            update_response = update_author(name: author.name, input: prepare_author(valid_attrs()), access_token: access_token, conn: shared.conn, locale: unquote(locale))

            expect ~i(update_response.errors) |> not_to(be_empty())
            expect ~i(update_response.errors[0].operation) |> to(eq("updateAuthor"))
            expect ~i(update_response.errors[0].entity) |> to(eq("author"))
            expect ~i(update_response.errors[0].code) |> to(eq("missing"))
            expect ~i(update_response.errors[0].field) |> to(eq("name"))
            expect ~i(update_response.errors[0].message) |> to(eq(unquote(msg)))
          end
        end)

        [
          en: "Cannot find author with specified email",
          ru: "Автор с указанным email не найден"
        ] |> Enum.each(fn {locale, msg} ->
          it "returns error for unknown email (#{locale})", validation: true, valid: true, locale: locale do
            author = build(:author)

            %{access_token: access_token} = creator()

            update_response = update_author(email: author.email, input: prepare_author(valid_attrs()), access_token: access_token, conn: shared.conn, locale: unquote(locale))

            expect ~i(update_response.errors) |> not_to(be_empty())
            expect ~i(update_response.errors[0].operation) |> to(eq("updateAuthor"))
            expect ~i(update_response.errors[0].entity) |> to(eq("author"))
            expect ~i(update_response.errors[0].code) |> to(eq("missing"))
            expect ~i(update_response.errors[0].field) |> to(eq("email"))
            expect ~i(update_response.errors[0].message) |> to(eq(unquote(msg)))
          end
        end)

        [
          en: "Author with the same name %{name} is already exist",
          ru: "Автор с аналогичным именем %{name} уже существует"
        ] |> Enum.each(fn {locale, msg} ->
          it "returns error for existing name (#{locale})", validation: true, valid: false, locale: locale do
            author = build(:author)

            %{access_token: access_token} = creator()

            existing_author = build(:author)
            create_author(input: prepare_author(existing_author), access_token: access_token, conn: shared.conn)

            create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

            update_response = update_author(name: author.name, input: %{name: existing_author.name |> String.upcase()}, access_token: access_token, conn: shared.conn, locale: unquote(locale))

            expect ~i(update_response.errors) |> not_to(be_empty())
            expect ~i(update_response.errors[0].operation) |> to(eq("updateAuthor"))
            expect ~i(update_response.errors[0].entity) |> to(eq("author"))
            expect ~i(update_response.errors[0].code) |> to(eq("unique"))
            expect ~i(update_response.errors[0].field) |> to(eq("name"))
            expect ~i(update_response.errors[0].message) |> to(eq(unquote(msg) |> String.replace("%{name}", String.downcase(existing_author.name))))
          end
        end)

        [
          en: "Author with the same email %{email} is already exist",
          ru: "Автор с аналогичным email %{email} уже существует"
        ] |> Enum.each(fn {locale, msg} ->
          it "returns error for existing email (#{locale})", validation: true, valid: false, locale: locale do
            author = build(:author)

            %{access_token: access_token} = creator()

            existing_author = build(:author)
            create_author(input: prepare_author(existing_author), access_token: access_token, conn: shared.conn)

            create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

            update_response = update_author(name: author.name, input: %{email: existing_author.email |> String.upcase()}, access_token: access_token, conn: shared.conn, locale: unquote(locale))

            expect ~i(update_response.errors) |> not_to(be_empty())
            expect ~i(update_response.errors[0].operation) |> to(eq("updateAuthor"))
            expect ~i(update_response.errors[0].entity) |> to(eq("author"))
            expect ~i(update_response.errors[0].code) |> to(eq("unique"))
            expect ~i(update_response.errors[0].field) |> to(eq("email"))
            expect ~i(update_response.errors[0].message) |> to(eq(unquote(msg) |> String.replace("%{email}", String.downcase(existing_author.email))))
          end
        end)

        [
          en: "Author name cannot be empty",
          ru: "Имя автора не может быть пустым"
        ] |> Enum.each(fn {locale, msg} ->
          it "returns error for empty name (#{locale})", validation: true, valid: false, locale: locale do
            author = build(:author)

            %{access_token: access_token} = creator()
            create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

            update_response = update_author(email: author.email, input: prepare_author(valid_attrs()) |> Map.put(:name, nil), access_token: access_token, conn: shared.conn, locale: unquote(locale))

            expect ~i(update_response.errors) |> not_to(be_empty())
            expect ~i(update_response.errors[0].operation) |> to(eq("updateAuthor"))
            expect ~i(update_response.errors[0].entity) |> to(eq("author"))
            expect ~i(update_response.errors[0].code) |> to(eq("required"))
            expect ~i(update_response.errors[0].field) |> to(eq("name"))
            expect ~i(update_response.errors[0].message) |> to(eq(unquote(msg)))

            update_response = update_author(email: author.email, input: prepare_author(valid_attrs()) |> Map.put(:name, ""), access_token: access_token, conn: shared.conn, locale: unquote(locale))

            expect ~i(update_response.errors) |> not_to(be_empty())
            expect ~i(update_response.errors[0].operation) |> to(eq("updateAuthor"))
            expect ~i(update_response.errors[0].entity) |> to(eq("author"))
            expect ~i(update_response.errors[0].code) |> to(eq("required"))
            expect ~i(update_response.errors[0].field) |> to(eq("name"))
            expect ~i(update_response.errors[0].message) |> to(eq(unquote(msg)))
          end
        end)

        [
          en: "Author name should be at least 3 characters long",
          ru: "Длина имени автора должна составлять минимум 3 символа"
        ] |> Enum.each(fn {locale, msg} ->
          it "returns error for too short name", validation: true, valid: false do
            author = build(:author)

            %{access_token: access_token} = creator()
            create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

            update_response = update_author(email: author.email, input: prepare_author(valid_attrs()) |> Map.put(:name, characters(1) |> to_string()), access_token: access_token, conn: shared.conn, locale: unquote(locale))

            expect ~i(update_response.errors) |> not_to(be_empty())
            expect ~i(update_response.errors[0].operation) |> to(eq("updateAuthor"))
            expect ~i(update_response.errors[0].entity) |> to(eq("author"))
            expect ~i(update_response.errors[0].code) |> to(eq("min"))
            expect ~i(update_response.errors[0].field) |> to(eq("name"))
            expect ~i(update_response.errors[0].message) |> to(eq(unquote(msg)))

            update_response = update_author(email: author.email, input: prepare_author(valid_attrs()) |> Map.put(:name, characters(2) |> to_string()), access_token: access_token, conn: shared.conn, locale: unquote(locale))

            expect ~i(update_response.errors) |> not_to(be_empty())
            expect ~i(update_response.errors[0].operation) |> to(eq("updateAuthor"))
            expect ~i(update_response.errors[0].entity) |> to(eq("author"))
            expect ~i(update_response.errors[0].code) |> to(eq("min"))
            expect ~i(update_response.errors[0].field) |> to(eq("name"))
            expect ~i(update_response.errors[0].message) |> to(eq(unquote(msg)))
          end
        end)

        [
          en: "Author name %{name} has invalid format",
          ru: "Имя автора %{name} не соответствует формату"
        ] |> Enum.each(fn {locale, msg} ->
          it "returns error for invalid name (#{locale})", validation: true, valid: false, locale: locale do
            %{access_token: access_token} = creator()

            author = build(:author)
            create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

            name = "оШиБкА"
            update_response = update_author(name: author.name, input: %{name: name}, access_token: access_token, conn: shared.conn, locale: unquote(locale))

            expect ~i(update_response.errors) |> not_to(be_empty())
            expect ~i(update_response.errors[0].operation) |> to(eq("updateAuthor"))
            expect ~i(update_response.errors[0].entity) |> to(eq("author"))
            expect ~i(update_response.errors[0].code) |> to(eq("format"))
            expect ~i(update_response.errors[0].field) |> to(eq("name"))
            expect ~i(update_response.errors[0].message) |> to(eq(unquote(msg) |> String.replace("%{name}", String.downcase(name))))
          end
        end)

        it "returns success for nil email", validation: true, valid: true do
          %{access_token: access_token} = creator()

          author = build(:author)
          create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

          update_response = update_author(email: author.email, input: prepare_author(valid_attrs()) |> Map.put(:email, nil), access_token: access_token, conn: shared.conn)
          expect ~i(update_response.errors) |> to(be_nil())

          expected_author = prepare_author(author) |> Map.merge(valid_attrs()) |> Map.put(:email, nil)
          assert check_author(~i(update_response.data.updateAuthor), expected_author)
        end

        it "returns success for empty email", validation: true, valid: true do
          %{access_token: access_token} = creator()

          author = build(:author)
          create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

          update_response = update_author(email: author.email, input: prepare_author(valid_attrs()) |> Map.put(:email, ""), access_token: access_token, conn: shared.conn)
          expect ~i(update_response.errors) |> to(be_nil())

          expected_author = prepare_author(author) |> Map.merge(valid_attrs()) |> Map.put(:email, nil)
          assert check_author(~i(update_response.data.updateAuthor), expected_author)
        end

        [
          en: "Author email %{email} has invalid format",
          ru: "Email автора %{email} не соответствует формату"
        ] |> Enum.each(fn {locale, msg} ->
          it "returns error for invalid email (#{locale})", validation: true, valid: false, locale: locale do
            %{access_token: access_token} = creator()

            author = build(:author)
            create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

            email = word() |> String.upcase()
            update_response = update_author(email: author.email, input: %{email: email}, access_token: access_token, conn: shared.conn, locale: unquote(locale))

            expect ~i(update_response.errors) |> not_to(be_empty())
            expect ~i(update_response.errors[0].operation) |> to(eq("updateAuthor"))
            expect ~i(update_response.errors[0].entity) |> to(eq("author"))
            expect ~i(update_response.errors[0].code) |> to(eq("format"))
            expect ~i(update_response.errors[0].field) |> to(eq("email"))
            expect ~i(update_response.errors[0].message) |> to(eq(unquote(msg) |> String.replace("%{email}", String.downcase(email))))
          end
        end)

        [
          en: "Not enough permissions to update author",
          ru: "Недостаточно прав для обновления автора"
        ] |> Enum.each(fn {locale, msg} ->
          it "returns error for anonymous user (#{locale})", validation: true, valid: false, locale: locale do
            author = build(:author)

            %{access_token: access_token} = creator()
            create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

            update_response = update_author(id: ~i(create_response.data.createAuthor.id), input: prepare_author(valid_attrs()), conn: shared.conn, locale: unquote(locale))

            expect ~i(update_response.errors) |> not_to(be_empty())
            expect ~i(update_response.errors[0].operation) |> to(eq("updateAuthor"))
            expect ~i(update_response.errors[0].entity) |> to(eq("author"))
            expect ~i(update_response.errors[0].code) |> to(eq("permissions"))
            expect ~i(update_response.errors[0].field) |> to(be_nil())
            expect ~i(update_response.errors[0].message) |> to(eq(unquote(msg)))
          end
        end)

        [
          en: "Cannot find author with specified id",
          ru: "Автор с указанным id не найден"
        ] |> Enum.each(fn {locale, msg} ->
          it "returns error for already deleted author (#{locale})", validation: true, valid: false, locale: locale do
            author = build(:author)

            %{access_token: access_token} = creator()
            create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)
            delete_author(id: ~i(create_response.data.createAuthor.id), access_token: access_token, conn: shared.conn)

            update_response = update_author(id: ~i(create_response.data.createAuthor.id), input: prepare_author(valid_attrs()), access_token: access_token, conn: shared.conn, locale: unquote(locale))

            expect ~i(update_response.errors) |> not_to(be_empty())
            expect ~i(update_response.errors[0].operation) |> to(eq("updateAuthor"))
            expect ~i(update_response.errors[0].entity) |> to(eq("author"))
            expect ~i(update_response.errors[0].code) |> to(eq("missing"))
            expect ~i(update_response.errors[0].field) |> to(eq("id"))
            expect ~i(update_response.errors[0].message) |> to(eq(unquote(msg)))
          end
        end)

        it "accepts note for revision", audit: true do
          author = build(:author)

          %{access_token: access_token} = creator()
          create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

          note = sentence()
          update_response = update_author(id: ~i(create_response.data.createAuthor.id), input: %{note: note}, access_token: access_token, conn: shared.conn)

          expect ~i(update_response.data.updateAuthor.note) |> to(eq(note))
        end

        it "increments revision version", audit: true do
          author = build(:author)

          %{access_token: access_token} = creator()
          create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)
          update_response = update_author(id: ~i(create_response.data.createAuthor.id), input: prepare_author(valid_attrs()), access_token: access_token, conn: shared.conn)

          expect ~i(update_response.data.updateAuthor.version) |> to(be(:>, ~i(create_response.data.createAuthor.version)))
        end

        it "sets updated_by to non-nil if context is not empty", audit: true do
          author = build(:author)

          %{access_token: access_token, id: updator_id} = creator()
          create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)
          update_response = update_author(id: ~i(create_response.data.createAuthor.id), input: prepare_author(valid_attrs()), access_token: access_token, conn: shared.conn)

          expect ~i(update_response.data.updateAuthor.updated_by.id) |> to(eq(updator_id))
        end

        it "does not touch created_at", audit: true do
          author = build(:author)

          %{access_token: access_token} = creator()
          create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)
          update_response = update_author(id: ~i(create_response.data.createAuthor.id), input: prepare_author(valid_attrs()), access_token: access_token, conn: shared.conn)

          expect ~i(update_response.data.updateAuthor.created_at) |> to(eq(~i(create_response.data.createAuthor.created_at)))
        end

        it "touches updated_at", audit: true do
          author = build(:author)

          %{access_token: access_token} = creator()
          create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)
          update_response = update_author(id: ~i(create_response.data.createAuthor.id), input: prepare_author(valid_attrs()), access_token: access_token, conn: shared.conn)

          expect ~i(create_response.data.createAuthor.updated_at) |> to(be_nil())
          expect ~i(update_response.data.updateAuthor.updated_at) |> not_to(be_nil())
        end

        it "updates translated fields", audit: true do
          author = build(:author)

          %{access_token: access_token} = creator()
          create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

          update_response = update_author(id: ~i(create_response.data.createAuthor.id), input: translation(), access_token: access_token, conn: shared.conn)

          expect ~i(update_response.data.updateAuthor.first_name)  |> not_to(eq(author.first_name))
          expect ~i(update_response.data.updateAuthor.last_name)   |> not_to(eq(author.last_name))
          expect ~i(update_response.data.updateAuthor.middle_name) |> not_to(eq(author.middle_name))

          expect ~i(update_response.data.updateAuthor.first_name)  |> to(eq(translation().first_name))
          expect ~i(update_response.data.updateAuthor.last_name)   |> to(eq(translation().last_name))
          expect ~i(update_response.data.updateAuthor.middle_name) |> to(eq(translation().middle_name))

          translations = ~i(update_response.data.updateAuthor.translations)

          default_translation = translations |> Enum.filter(fn item -> ~i(item.locale) |> String.downcase() == I18n.default_locale() end) |> Enum.at(0)

          expect ~i(default_translation.first_name)  |> not_to(eq(author.first_name))
          expect ~i(default_translation.last_name)   |> not_to(eq(author.last_name))
          expect ~i(default_translation.middle_name) |> not_to(eq(author.middle_name))

          expect ~i(default_translation.first_name)  |> to(eq(translation().first_name))
          expect ~i(default_translation.last_name)   |> to(eq(translation().last_name))
          expect ~i(default_translation.middle_name) |> to(eq(translation().middle_name))
        end

        it "updates translations list", audit: true do
          default = translation_with_default_locale()
          custom = translation_with_custom_locale()

          author = build(:author)

          %{access_token: access_token} = creator()
          create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

          update_response = update_author(id: ~i(create_response.data.createAuthor.id), input: %{translations: [default, custom]}, access_token: access_token, conn: shared.conn)

          expect ~i(update_response.data.updateAuthor.first_name)  |> to(eq(default.first_name))
          expect ~i(update_response.data.updateAuthor.last_name)   |> to(eq(default.last_name))
          expect ~i(update_response.data.updateAuthor.middle_name) |> to(eq(default.middle_name))

          translations = ~i(update_response.data.updateAuthor.translations)

          default_translation = translations |> Enum.filter(fn item -> ~i(item.locale) == default.locale end) |> Enum.at(0)
          custom_translation  = translations |> Enum.filter(fn item -> ~i(item.locale) == custom.locale  end) |> Enum.at(0)

          expect ~i(default_translation.first_name)  |> to(eq(default.first_name))
          expect ~i(default_translation.last_name)   |> to(eq(default.last_name))
          expect ~i(default_translation.middle_name) |> to(eq(default.middle_name))

          expect ~i(custom_translation.first_name)  |> to(eq(custom.first_name))
          expect ~i(custom_translation.last_name)   |> to(eq(custom.last_name))
          expect ~i(custom_translation.middle_name) |> to(eq(custom.middle_name))
        end

        it "allows to remove translations", audit: true do
          default = translation_with_default_locale()
          custom = translation_with_custom_locale()

          author = build(:author)

          %{access_token: access_token} = creator()
          create_response = create_author(input: prepare_author(author) |> Map.put(:translations, [custom]), access_token: access_token, conn: shared.conn)

          update_response = update_author(id: ~i(create_response.data.createAuthor.id), input: %{translations: [default]}, access_token: access_token, conn: shared.conn)

          expect ~i(update_response.data.updateAuthor.first_name)  |> to(eq(default.first_name))
          expect ~i(update_response.data.updateAuthor.last_name)   |> to(eq(default.last_name))
          expect ~i(update_response.data.updateAuthor.middle_name) |> to(eq(default.middle_name))

          translations = ~i(update_response.data.updateAuthor.translations)

          default_translation = translations |> Enum.filter(fn item -> ~i(item.locale) == default.locale end) |> Enum.at(0)

          expect ~i(default_translation.first_name)  |> to(eq(default.first_name))
          expect ~i(default_translation.last_name)   |> to(eq(default.last_name))
          expect ~i(default_translation.middle_name) |> to(eq(default.middle_name))

          custom_translation = translations |> Enum.filter(fn item -> ~i(item.locale) == custom.locale  end) |> Enum.at(0)
          refute custom_translation
        end

        it "allows to remove translations", audit: true do
          author = build(:author)

          %{access_token: access_token} = creator()
          create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

          update_response = update_author(id: ~i(create_response.data.createAuthor.id), input: %{translations: []}, access_token: access_token, conn: shared.conn)

          expect ~i(update_response.data.updateAuthor.first_name)   |> to(eq(""))
          expect ~i(update_response.data.updateAuthor.last_name)    |> to(eq(""))
          expect ~i(update_response.data.updateAuthor.middle_name)  |> to(eq(""))
          expect ~i(update_response.data.updateAuthor.translations) |> to(eq([]))
        end

        it "return error for unknown locale", audit: true do
          author = build(:author)

          %{access_token: access_token} = creator()
          create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

          update_response = update_user(id: ~i(create_response.data.createAuthor.id), input: %{translations: [translation_with_unknown_locale()]}, access_token: access_token, conn: shared.conn)

          expect ~i(update_response.errors) |> not_to(be_empty())
          expect ~i(update_response.errors[0].operation) |> to(be_nil())
        end

        [:user, :moderator, :admin]
        |> Enum.each(fn user_role ->
          it "allows #{user_role} to update himself", permission: true, allow: true, self: true do
            user = build(unquote(user_role))
            author = build(:author)

            %{access_token: access_token} = creator()
            create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

            note = word()
            access_token = auth(user, author, shared.conn)
            update_response = update_author(id: ~i(create_response.data.createUser.author.id), input: %{note: note}, access_token: access_token, conn: shared.conn)

            expect ~i(update_response.errors) |> to(be_nil())
          end
        end)

        [:user, :moderator, :admin]
        |> Enum.each(fn user_role ->
          it "allows #{user_role} to update unassigned", permission: true, allow: true, self: true do
            author = build(:author)

            %{access_token: access_token} = creator()
            create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

            note = word()
            %{access_token: access_token} = unquote(:"creator_#{user_role}")()
            update_response = update_author(id: ~i(create_response.data.createAuthor.id), input: %{note: note}, access_token: access_token, conn: shared.conn)

            expect ~i(update_response.errors) |> to(be_nil())
          end
        end)

        [
          en: "Not enough permissions to update author",
          ru: "Недостаточно прав для обновления автора"
        ] |> Enum.each(fn {locale, msg} ->
          [
            user:      [user: false, moderator: true,  admin: true],
            moderator: [user: false, moderator: false, admin: true],
            admin:     [user: false, moderator: false, admin: false],
          ] |> Enum.each(fn({user_role, cols}) ->
            cols |> Enum.each(fn({role, is_allowed}) ->
                it "#{if is_allowed, do: "allows", else: "does not allow"} #{role} to update #{user_role} (#{locale})", permission: true, allow: is_allowed, role: role, locale: locale do
                  user = build(unquote(user_role))
                  author = build(:author)

                  %{access_token: access_token} = creator()
                  create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

                  name = slug()
                  %{access_token: access_token} = unquote(:"creator_#{role}")()
                  update_response = update_author(id: ~i(create_response.data.createUser.author.id), input: %{name: name}, access_token: access_token, conn: shared.conn, locale: unquote(locale))

                  if unquote(is_allowed) do
                    expect ~i(update_response.errors) |> to(be_nil())
                  else
                    expect ~i(update_response.errors) |> not_to(be_empty())
                    expect ~i(update_response.errors[0].operation) |> to(eq("updateAuthor"))
                    expect ~i(update_response.errors[0].entity) |> to(eq("author"))
                    expect ~i(update_response.errors[0].code) |> to(eq("permissions"))
                    expect ~i(update_response.errors[0].field) |> to(be_nil())
                    expect ~i(update_response.errors[0].message) |> to(eq(unquote(msg)))
                  end
                end
            end)
          end)
        end)
      end

      describe "deleteAuthor" do
        it "returns success for valid id", validation: true, valid: true do
          author = build(:author)

          %{access_token: access_token} = creator()
          create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)
          delete_response = delete_author(id: ~i(create_response.data.createAuthor.id), access_token: access_token, conn: shared.conn)

          expect ~i(delete_response.errors) |> to(be_nil())
          expect ~i(delete_response.data.deleteAuthor) |> to(be_nil())
        end

        it "returns success for valid name", validation: true, valid: true do
          author = build(:author)

          %{access_token: access_token} = creator()
          create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)
          delete_response = delete_author(name: author.name, access_token: access_token, conn: shared.conn)

          expect ~i(delete_response.errors) |> to(be_nil())
          expect ~i(delete_response.data.deleteAuthor) |> to(be_nil())
        end

        it "returns success for valid email", validation: true, valid: true do
          author = build(:author)

          %{access_token: access_token} = creator()
          create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)
          delete_response = delete_author(email: author.email, access_token: access_token, conn: shared.conn)

          expect ~i(delete_response.errors) |> to(be_nil())
          expect ~i(delete_response.data.deleteAuthor) |> to(be_nil())
        end

        it "returns success for current user", validation: true, valid: true, self: true do
          user = build(:user)
          author = build(:author)

          %{access_token: access_token} = creator()
          create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

          access_token = auth(user, author, shared.conn)
          delete_response = delete_author(access_token: access_token, conn: shared.conn)

          expect ~i(delete_response.errors) |> to(be_nil())
          expect ~i(delete_response.data.deleteAuthor) |> to(be_nil())
        end

        [
          en: "Cannot find author with specified id",
          ru: "Автор с указанным id не найден"
        ] |> Enum.each(fn {locale, msg} ->
          it "returns error for unknown id (#{locale})", validation: true, valid: false, locale: locale do
            %{access_token: access_token} = creator()
            delete_response = delete_author(id: domain_uuid(:author), access_token: access_token, conn: shared.conn, locale: unquote(locale))

            expect ~i(delete_response.errors) |> not_to(be_empty())
            expect ~i(delete_response.errors[0].operation) |> to(eq("deleteAuthor"))
            expect ~i(delete_response.errors[0].entity) |> to(eq("author"))
            expect ~i(delete_response.errors[0].code) |> to(eq("missing"))
            expect ~i(delete_response.errors[0].field) |> to(eq("id"))
            expect ~i(delete_response.errors[0].message) |> to(eq(unquote(msg)))
          end
        end)

        [
          en: "Cannot find author with specified name",
          ru: "Автор с указанным именем не найден"
        ] |> Enum.each(fn {locale, msg} ->
          it "returns error for unknown name (#{locale})", validation: true, valid: false, locale: locale do
            author = build(:author)

            %{access_token: access_token} = creator()
            delete_response = delete_author(name: author.name, access_token: access_token, conn: shared.conn, locale: unquote(locale))

            expect ~i(delete_response.errors) |> not_to(be_empty())
            expect ~i(delete_response.errors[0].operation) |> to(eq("deleteAuthor"))
            expect ~i(delete_response.errors[0].entity) |> to(eq("author"))
            expect ~i(delete_response.errors[0].code) |> to(eq("missing"))
            expect ~i(delete_response.errors[0].field) |> to(eq("name"))
            expect ~i(delete_response.errors[0].message) |> to(eq(unquote(msg)))
          end
        end)

        [
          en: "Cannot find author with specified email",
          ru: "Автор с указанным email не найден"
        ] |> Enum.each(fn {locale, msg} ->
          it "returns error for unknown email (#{locale})", validation: true, valid: false, locale: locale do
            author = build(:author)

            %{access_token: access_token} = creator()
            delete_response = delete_author(email: author.email, access_token: access_token, conn: shared.conn, locale: unquote(locale))

            expect ~i(delete_response.errors) |> not_to(be_empty())
            expect ~i(delete_response.errors[0].operation) |> to(eq("deleteAuthor"))
            expect ~i(delete_response.errors[0].entity) |> to(eq("author"))
            expect ~i(delete_response.errors[0].code) |> to(eq("missing"))
            expect ~i(delete_response.errors[0].field) |> to(eq("email"))
            expect ~i(delete_response.errors[0].message) |> to(eq(unquote(msg)))
          end
        end)

        [
          en: "Not enough permissions to delete author",
          ru: "Недостаточно прав для удаления автора"
        ] |> Enum.each(fn {locale, msg} ->
          it "returns error for anonymous user (#{locale})", validation: true, valid: false, locale: locale do
            author = build(:author)

            %{access_token: access_token} = creator()
            create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

            delete_response = delete_author(id: ~i(create_response.data.createAuthor.id), conn: shared.conn, locale: unquote(locale))

            expect ~i(delete_response.errors) |> not_to(be_empty())
            expect ~i(delete_response.errors[0].operation) |> to(eq("deleteAuthor"))
            expect ~i(delete_response.errors[0].entity) |> to(eq("author"))
            expect ~i(delete_response.errors[0].code) |> to(eq("permissions"))
            expect ~i(delete_response.errors[0].field) |> to(be_nil())
            expect ~i(delete_response.errors[0].message) |> to(eq(unquote(msg)))
          end
        end)

        it "accepts note for revision", audit: true do
          author = build(:author)

          %{access_token: access_token} = creator()
          create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

          note = sentence()
          delete_response = delete_author(id: ~i(create_response.data.createAuthor.id), input: %{note: note}, access_token: access_token, conn: shared.conn)

          expect ~i(delete_response.errors) |> to(be_nil())
        end

        [
          en: "Cannot find author with specified id",
          ru: "Автор с указанным id не найден"
        ] |> Enum.each(fn {locale, msg} ->
          it "returns error for already deleted author (#{locale})", validation: true, valid: false, locale: locale do
            author = build(:author)

            %{access_token: access_token} = creator()
            create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)
            delete_author(id: ~i(create_response.data.createAuthor.id), access_token: access_token, conn: shared.conn)

            delete_response = delete_author(id: ~i(create_response.data.createAuthor.id), access_token: access_token, conn: shared.conn, locale: unquote(locale))

            expect ~i(delete_response.errors) |> not_to(be_empty())
            expect ~i(delete_response.errors[0].operation) |> to(eq("deleteAuthor"))
            expect ~i(delete_response.errors[0].entity) |> to(eq("author"))
            expect ~i(delete_response.errors[0].code) |> to(eq("missing"))
            expect ~i(delete_response.errors[0].field) |> to(eq("id"))
            expect ~i(delete_response.errors[0].message) |> to(eq(unquote(msg)))
          end
        end)

        [:user, :moderator, :admin]
        |> Enum.each(fn(user_role) ->
          it "allows #{user_role} to delete himself", permission: true, allow: true, self: true do
            user = build(unquote(user_role))
            author = build(:author)

            %{access_token: access_token} = creator()
            create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

            access_token = auth(user, author, shared.conn)
            delete_response = delete_author(id: ~i(create_response.data.createUser.author.id), access_token: access_token, conn: shared.conn)

            expect ~i(delete_response.errors) |> to(be_nil())
          end
        end)

        [:user, :moderator, :admin]
        |> Enum.each(fn(user_role) ->
          it "allows #{user_role} to delete unassigned", permission: true, allow: true, self: true do
            author = build(:author)

            %{access_token: access_token} = creator()
            create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

            %{access_token: access_token} = unquote(:"creator_#{user_role}")()
            delete_response = delete_author(id: ~i(create_response.data.createAuthor.id), access_token: access_token, conn: shared.conn)

            expect ~i(delete_response.errors) |> to(be_nil())
          end
        end)

        [
          en: "Not enough permissions to delete author",
          ru: "Недостаточно прав для удаления автора"
        ] |> Enum.each(fn {locale, msg} ->
          [
            user:      [user: false, moderator: true,   admin: true],
            moderator: [user: false, moderator: false,  admin: true],
            admin:     [user: false, moderator: false,  admin: false],
          ] |> Enum.each(fn({user_role, cols}) ->
            cols |> Enum.each(fn({role, is_allowed}) ->
                it "#{if is_allowed, do: "allows", else: "does not allow"} #{role} to delete #{user_role} (#{locale})", permission: true, allow: is_allowed, role: user_role, locale: locale do
                  user = build(unquote(user_role))
                  author = build(:author)

                  %{access_token: access_token} = creator()
                  create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

                  %{access_token: access_token} = unquote(:"creator_#{role}")()
                  delete_response = delete_author(id: ~i(create_response.data.createUser.author.id), access_token: access_token, conn: shared.conn, locale: unquote(locale))

                  if unquote(is_allowed) do
                    expect ~i(delete_response.errors) |> to(be_nil())
                  else
                    expect ~i(delete_response.errors) |> not_to(be_empty())
                    expect ~i(delete_response.errors[0].operation) |> to(eq("deleteAuthor"))
                    expect ~i(delete_response.errors[0].entity) |> to(eq("author"))
                    expect ~i(delete_response.errors[0].code) |> to(eq("permissions"))
                    expect ~i(delete_response.errors[0].field) |> to(be_nil())
                    expect ~i(delete_response.errors[0].message) |> to(eq(unquote(msg)))
                  end
                end
            end)
          end)
        end)
      end
    end
  end
end
