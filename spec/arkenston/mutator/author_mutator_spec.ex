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
    %{locale: I18n.locale, first_name: first_name(), last_name: last_name(), middle_name: first_name()}
  end

  let :translation_with_custom_locale do
    %{locale: "ru", first_name: first_name(), last_name: last_name(), middle_name: first_name()}
  end

  let :translation_with_unknown_locale do
    %{locale: characters(2) |> to_string(), first_name: first_name(), last_name: last_name(), middle_name: first_name()}
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

          assert ~i(create_response.successful)
          assert check_user(~i(create_response.result), prepare_author(author))
        end

        it "returns error for already used name", validation: true, valid: false do
          %{access_token: access_token} = creator()

          existing_author = build(:author)
          create_author(input: prepare_author(existing_author), access_token: access_token, conn: shared.conn)

          invalid_author = build(:author, name: existing_author.name |> String.upcase())

          create_response = create_author(input: prepare_author(invalid_author), access_token: access_token, conn: shared.conn)

          refute ~i(create_response.successful)
        end

        it "returns error for already used email", validation: true, valid: false do
          %{access_token: access_token} = creator()

          existing_author = build(:author)
          create_author(input: prepare_author(existing_author), access_token: access_token, conn: shared.conn)

          invalid_author = build(:author, email: existing_author.email |> String.upcase())

          create_response = create_author(input: prepare_author(invalid_author), access_token: access_token, conn: shared.conn)

          refute ~i(create_response.successful)
        end

        it "returns error for empty name", validation: true, valid: false do
          author = build(:author)

          create_response = create_author(input: prepare_author(author) |> Map.drop([:name]), conn: shared.conn)
          refute ~i(create_response.successful)

          create_response = create_author(input: prepare_author(author) |> Map.put(:name, nil), conn: shared.conn)
          refute ~i(create_response.successful)
        end

        it "returns success without email", validation: true, valid: true do
          %{access_token: access_token} = creator()

          author = build(:author)
          create_response = create_author(input: prepare_author(author) |> Map.drop([:email]), access_token: access_token, conn: shared.conn)

          assert ~i(create_response.successful)
          assert check_user(~i(create_response.result), prepare_author(author) |> Map.put(:email, nil))
        end

        it "returns success for nil email", validation: true, valid: true do
          %{access_token: access_token} = creator()

          author = build(:author)
          create_response = create_author(input: prepare_author(author) |> Map.put(:email, nil), access_token: access_token, conn: shared.conn)
          assert ~i(create_response.successful)
          assert check_user(~i(create_response.result), prepare_author(author) |> Map.put(:email, nil))
        end

        it "returns success for empty email", validation: true, valid: true do
          %{access_token: access_token} = creator()

          author = build(:author)
          create_response = create_author(input: prepare_author(author) |> Map.put(:email, ""), access_token: access_token, conn: shared.conn)
          assert ~i(create_response.successful)
          assert check_user(~i(create_response.result), prepare_author(author) |> Map.put(:email, nil))
        end

        it "accepts note for revision", audit: true do
          note = sentence()
          author = build(:author)

          %{access_token: access_token} = creator()
          create_response = create_author(input: prepare_author(author) |> Map.merge(%{note: note}), access_token: access_token, conn: shared.conn)
          expect ~i(create_response.result.note) |> to(eq(note))
        end

        it "sets revision version to 1", audit: true do
          author = build(:author)

          %{access_token: access_token} = creator()
          create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

          expect ~i(create_response.result.version) |> to(eq(1))
        end

        it "sets created_by to non-nil if context is not empty", audit: true do
          author = build(:author)

          %{access_token: access_token, id: creator_id} = creator()
          create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

          expect ~i(create_response.result.created_by.id) |> to(eq(creator_id))
        end

        it "returns error for anonymous user", validation: true, valid: false do
          author = build(:author)

          create_response = create_author(input: prepare_author(author), conn: shared.conn)

          refute ~i(create_response.successful)
        end

        it "sets created_by to nil if context is empty", audit: true, role: :anonymous do
          user = build(:user)
          author = build(:author)

          create_response = create_user(input: prepare_user(user), author: prepare_author(author), conn: shared.conn)

          get_one_response = get_author(id: ~i(create_response.result.author.id), conn: shared.conn)

          expect ~i(get_one_response.result.created_by) |> to(be_nil())
        end

        it "saves translated fields", audit: true do
          author = build(:author, translation())

          %{access_token: access_token} = creator()
          create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

          expect ~i(create_response.result.first_name)  |> to(eq(translation().first_name))
          expect ~i(create_response.result.last_name)   |> to(eq(translation().last_name))
          expect ~i(create_response.result.middle_name) |> to(eq(translation().middle_name))

          translations = ~i(create_response.result.translations)

          default_translation = translations |> Enum.filter(fn item -> ~i(item.locale) == I18n.locale end) |> Enum.at(0)

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

          expect ~i(create_response.result.first_name)  |> to(eq(default.first_name))
          expect ~i(create_response.result.last_name)   |> to(eq(default.last_name))
          expect ~i(create_response.result.middle_name) |> to(eq(default.middle_name))

          translations = ~i(create_response.result.translations)

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

          refute ~i(create_response.success)
        end

        it "sets created_at", audit: true do
          author = build(:author)

          %{access_token: access_token} = creator()
          create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

          expect ~i(create_response.result.created_at) |> not_to(be_nil())
        end

        [:user, :moderator, :admin]
        |> Enum.each(fn role ->
            it "allows to create new author by #{role}", permission: true, allow: true, role: role do
              author = build(:author)

              %{access_token: access_token} = unquote(:"creator_#{role}")()
              create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

              assert ~i(create_response.successful)
            end
        end)
      end

      describe "updateAuthor" do
        it "returns success for valid id", validation: true, valid: true do
          author = build(:author)

          %{access_token: access_token} = creator()
          create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

          update_response = update_author(id: ~i(create_response.result.id), input: prepare_author(valid_attrs()), access_token: access_token, conn: shared.conn)

          assert ~i(update_response.successful)

          expected_user = prepare_author(author) |> Map.merge(valid_attrs())
          assert check_user(~i(update_response.result), expected_user)
        end

        it "returns error for unknown id", validation: true, valid: false do
          %{access_token: access_token} = creator()
          update_response = update_author(id: domain_uuid(:author), input: prepare_author(valid_attrs()), access_token: access_token, conn: shared.conn)

          refute ~i(update_response.successful)
        end

        it "returns success for valid name", validation: true, valid: true do
          author = build(:author)

          %{access_token: access_token} = creator()
          create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

          update_response = update_author(id: ~i(create_response.result.id), input: prepare_author(valid_attrs()), access_token: access_token, conn: shared.conn)

          assert ~i(update_response.successful)

          expected_user = prepare_author(author) |> Map.merge(valid_attrs())
          assert check_user(~i(update_response.result), expected_user)
        end

        it "returns error for existing name", validation: true, valid: false do
          author = build(:author)

          %{access_token: access_token} = creator()

          existing_author = build(:author)
          create_author(input: prepare_author(existing_author), access_token: access_token, conn: shared.conn)

          create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

          update_response = update_author(name: author.name, input: %{name: existing_author.name |> String.upcase()}, access_token: access_token, conn: shared.conn)

          refute ~i(update_response.successful)
        end

        it "returns error for unknown name", validation: true, valid: true do
          author = build(:author)

          %{access_token: access_token} = creator()

          update_response = update_author(name: author.name, input: prepare_author(valid_attrs()), access_token: access_token, conn: shared.conn)

          refute ~i(update_response.successful)
        end

        it "returns success for valid email", validation: true, valid: true do
          author = build(:author)

          %{access_token: access_token} = creator()
          create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

          update_response = update_author(email: author.email, input: prepare_author(valid_attrs()), access_token: access_token, conn: shared.conn)

          assert ~i(update_response.successful)

          expected_user = prepare_author(author) |> Map.merge(valid_attrs())
          assert check_user(~i(update_response.result), expected_user)
        end

        it "returns error for unknown email", validation: true, valid: true do
          author = build(:author)

          %{access_token: access_token} = creator()

          update_response = update_author(email: author.email, input: prepare_author(valid_attrs()), access_token: access_token, conn: shared.conn)

          refute ~i(update_response.successful)
        end

        it "returns error for existing email", validation: true, valid: false do
          author = build(:author)

          %{access_token: access_token} = creator()

          existing_author = build(:author)
          create_author(input: prepare_author(existing_author), access_token: access_token, conn: shared.conn)

          create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

          update_response = update_author(name: author.name, input: %{email: existing_author.email |> String.upcase()}, access_token: access_token, conn: shared.conn)

          refute ~i(update_response.successful)
        end

        it "returns error for empty name", validation: true, valid: false do
          author = build(:author)

          %{access_token: access_token} = creator()
          create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

          update_response = update_author(email: author.email, input: prepare_author(valid_attrs()) |> Map.put(:name, nil), access_token: access_token, conn: shared.conn)
          refute ~i(update_response.successful)
        end

        it "returns success for nil email", validation: true, valid: true do
          author = build(:author)

          %{access_token: access_token} = creator()
          create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

          update_response = update_author(email: author.email, input: prepare_author(valid_attrs()) |> Map.put(:email, nil), access_token: access_token, conn: shared.conn)
          assert ~i(update_response.successful)

          expected_user = prepare_author(author) |> Map.merge(valid_attrs()) |> Map.put(:email, nil)
          assert check_user(~i(update_response.result), expected_user)
        end

        it "returns success for empty email", validation: true, valid: true do
          author = build(:author)

          %{access_token: access_token} = creator()
          create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

          update_response = update_author(email: author.email, input: prepare_author(valid_attrs()) |> Map.put(:email, ""), access_token: access_token, conn: shared.conn)
          assert ~i(update_response.successful)

          expected_user = prepare_author(author) |> Map.merge(valid_attrs()) |> Map.put(:email, nil)
          assert check_user(~i(update_response.result), expected_user)
        end

        it "returns success for current user", validation: true, valid: true do
          user = build(:user)
          author = build(:author)

          %{access_token: access_token} = creator()
          create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

          access_token = auth(user, author, shared.conn)
          update_response = update_author(input: prepare_author(valid_attrs()), access_token: access_token, conn: shared.conn)

          assert ~i(update_response.successful)
          expected_user = prepare_author(author) |> Map.merge(valid_attrs())
          assert check_user(~i(update_response.result), expected_user)
        end

        it "returns error for anonymous user", validation: true, valid: false do
          author = build(:author)

          %{access_token: access_token} = creator()
          create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

          update_response = update_author(id: ~i(create_response.result.id), input: prepare_author(valid_attrs()), conn: shared.conn)

          refute ~i(update_response.successful)
        end

        it "returns error for already deleted author", validation: true, valid: false do
          author = build(:author)

          %{access_token: access_token} = creator()
          create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)
          delete_author(id: ~i(create_response.result.id), access_token: access_token, conn: shared.conn)

          update_response = update_author(id: ~i(create_response.result.id), input: prepare_author(valid_attrs()), access_token: access_token, conn: shared.conn)

          refute ~i(update_response.successful)
        end

        it "accepts note for revision", audit: true do
          author = build(:author)

          %{access_token: access_token} = creator()
          create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

          note = sentence()
          update_response = update_author(id: ~i(create_response.result.id), input: %{note: note}, access_token: access_token, conn: shared.conn)

          expect ~i(update_response.result.note) |> to(eq(note))
        end

        it "increments revision version", audit: true do
          author = build(:author)

          %{access_token: access_token} = creator()
          create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)
          update_response = update_author(id: ~i(create_response.result.id), input: prepare_author(valid_attrs()), access_token: access_token, conn: shared.conn)

          expect ~i(update_response.result.version) |> to(be(:>, ~i(create_response.result.version)))
        end

        it "sets updated_by to non-nil if context is not empty", audit: true do
          author = build(:author)

          %{access_token: access_token, id: updator_id} = creator()
          create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)
          update_response = update_author(id: ~i(create_response.result.id), input: prepare_author(valid_attrs()), access_token: access_token, conn: shared.conn)

          expect ~i(update_response.result.updated_by.id) |> to(eq(updator_id))
        end

        it "does not touch created_at", audit: true do
          author = build(:author)

          %{access_token: access_token} = creator()
          create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)
          update_response = update_author(id: ~i(create_response.result.id), input: prepare_author(valid_attrs()), access_token: access_token, conn: shared.conn)

          expect ~i(update_response.result.created_at) |> to(eq(~i(create_response.result.created_at)))
        end

        it "touches updated_at", audit: true do
          author = build(:author)

          %{access_token: access_token} = creator()
          create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)
          update_response = update_author(id: ~i(create_response.result.id), input: prepare_author(valid_attrs()), access_token: access_token, conn: shared.conn)

          expect ~i(create_response.result.updated_at) |> to(be_nil())
          expect ~i(update_response.result.updated_at) |> not_to(be_nil())
        end

        it "updates translated fields", audit: true do
          author = build(:author)

          %{access_token: access_token} = creator()
          create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

          update_response = update_author(id: ~i(create_response.result.id), input: translation(), access_token: access_token, conn: shared.conn)

          expect ~i(update_response.result.first_name)  |> not_to(eq(author.first_name))
          expect ~i(update_response.result.last_name)   |> not_to(eq(author.last_name))
          expect ~i(update_response.result.middle_name) |> not_to(eq(author.middle_name))

          expect ~i(update_response.result.first_name)  |> to(eq(translation().first_name))
          expect ~i(update_response.result.last_name)   |> to(eq(translation().last_name))
          expect ~i(update_response.result.middle_name) |> to(eq(translation().middle_name))

          translations = ~i(update_response.result.translations)

          default_translation = translations |> Enum.filter(fn item -> ~i(item.locale) == I18n.locale end) |> Enum.at(0)

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

          update_response = update_author(id: ~i(create_response.result.id), input: %{translations: [default, custom]}, access_token: access_token, conn: shared.conn)

          expect ~i(update_response.result.first_name)  |> to(eq(default.first_name))
          expect ~i(update_response.result.last_name)   |> to(eq(default.last_name))
          expect ~i(update_response.result.middle_name) |> to(eq(default.middle_name))

          translations = ~i(update_response.result.translations)

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

          update_response = update_author(id: ~i(create_response.result.id), input: %{translations: [default]}, access_token: access_token, conn: shared.conn)

          expect ~i(update_response.result.first_name)  |> to(eq(default.first_name))
          expect ~i(update_response.result.last_name)   |> to(eq(default.last_name))
          expect ~i(update_response.result.middle_name) |> to(eq(default.middle_name))

          translations = ~i(update_response.result.translations)

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

          update_response = update_author(id: ~i(create_response.result.id), input: %{translations: []}, access_token: access_token, conn: shared.conn)

          expect ~i(update_response.result.first_name)   |> to(eq(""))
          expect ~i(update_response.result.last_name)    |> to(eq(""))
          expect ~i(update_response.result.middle_name)  |> to(eq(""))
          expect ~i(update_response.result.translations) |> to(eq([]))
        end

        it "return error for unknown locale", audit: true do
          author = build(:author)

          %{access_token: access_token} = creator()
          create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

          update_response = update_user(id: ~i(create_response.result.id), input: %{translations: [translation_with_unknown_locale()]}, access_token: access_token, conn: shared.conn)

          refute ~i(update_response.success)
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
            update_response = update_author(id: ~i(create_response.result.author.id), input: %{note: note}, access_token: access_token, conn: shared.conn)

            assert ~i(update_response.successful)
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
            update_response = update_author(id: ~i(create_response.result.id), input: %{note: note}, access_token: access_token, conn: shared.conn)

            assert ~i(update_response.successful)
          end
        end)

        [
          user:      [user: false, moderator: true,  admin: true],
          moderator: [user: false, moderator: false, admin: true],
          admin:     [user: false, moderator: false, admin: false],
        ] |> Enum.each(fn({user_role, cols}) ->
          cols |> Enum.each(fn({role, is_allowed}) ->
              it "#{if is_allowed, do: "allows", else: "does not allow"} #{role} to update #{user_role}", permission: true, allow: is_allowed, role: role do
                user = build(unquote(user_role))
                author = build(:author)

                %{access_token: access_token} = creator()
                create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

                name = slug()
                %{access_token: access_token} = unquote(:"creator_#{role}")()
                update_response = update_author(id: ~i(create_response.result.author.id), input: %{name: name}, access_token: access_token, conn: shared.conn)

                if unquote(is_allowed) do
                  assert ~i(update_response.successful)
                else
                  refute ~i(update_response.successful)
                end
              end
          end)
        end)
      end

      describe "deleteAuthor" do
        it "returns success for valid id", validation: true, valid: true do
          author = build(:author)

          %{access_token: access_token} = creator()
          create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)
          delete_response = delete_author(id: ~i(create_response.result.id), access_token: access_token, conn: shared.conn)

          assert ~i(delete_response.successful)
          expect ~i(delete_response.result) |> to(be_nil())
        end

        it "returns error for unknown id", validation: true, valid: false do
          %{access_token: access_token} = creator()
          delete_response = delete_author(id: domain_uuid(:author), access_token: access_token, conn: shared.conn)

          refute ~i(delete_response.successful)
        end

        it "returns success for valid name", validation: true, valid: true do
          author = build(:author)

          %{access_token: access_token} = creator()
          create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)
          delete_response = delete_author(name: author.name, access_token: access_token, conn: shared.conn)

          assert ~i(delete_response.successful)
          expect ~i(delete_response.result) |> to(be_nil())
        end

        it "returns error for unknown name", validation: true, valid: false do
          author = build(:author)

          %{access_token: access_token} = creator()
          delete_response = delete_author(name: author.name, access_token: access_token, conn: shared.conn)

          refute ~i(delete_response.successful)
        end

        it "returns success for valid email", validation: true, valid: true do
          author = build(:author)

          %{access_token: access_token} = creator()
          create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)
          delete_response = delete_author(email: author.email, access_token: access_token, conn: shared.conn)

          assert ~i(delete_response.successful)
          expect ~i(delete_response.result) |> to(be_nil())
        end

        it "returns error for unknown email", validation: true, valid: false do
          author = build(:author)

          %{access_token: access_token} = creator()
          delete_response = delete_author(email: author.email, access_token: access_token, conn: shared.conn)

          refute ~i(delete_response.successful)
        end

        it "returns success for current user", validation: true, valid: true, self: true do
          user = build(:user)
          author = build(:author)

          %{access_token: access_token} = creator()
          create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

          access_token = auth(user, author, shared.conn)
          delete_response = delete_author(access_token: access_token, conn: shared.conn)

          assert ~i(delete_response.successful)
          expect ~i(delete_response.result) |> to(be_nil())
        end

        it "returns error for anonymous user", validation: true, valid: false do
          author = build(:author)

          create_response = create_author(input: prepare_author(author), conn: shared.conn)
          delete_response = delete_author(id: ~i(create_response.result.id), conn: shared.conn)

          refute ~i(delete_response.successful)
        end

        it "accepts note for revision", audit: true do
          author = build(:author)

          %{access_token: access_token} = creator()
          create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

          note = sentence()
          delete_response = delete_author(id: ~i(create_response.result.id), input: %{note: note}, access_token: access_token, conn: shared.conn)

          assert ~i(delete_response.successful)
        end

        [:user, :moderator, :admin]
        |> Enum.each(fn(user_role) ->
          it "allows #{user_role} to delete himself", permission: true, allow: true, self: true do
            user = build(unquote(user_role))
            author = build(:author)

            %{access_token: access_token} = creator()
            create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

            access_token = auth(user, author, shared.conn)
            delete_response = delete_author(id: ~i(create_response.result.author.id), access_token: access_token, conn: shared.conn)

            assert ~i(delete_response.successful)
          end
        end)

        [:user, :moderator, :admin]
        |> Enum.each(fn(user_role) ->
          it "allows #{user_role} to delete unassigned", permission: true, allow: true, self: true do
            author = build(:author)

            %{access_token: access_token} = creator()
            create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

            %{access_token: access_token} = unquote(:"creator_#{user_role}")()
            delete_response = delete_author(id: ~i(create_response.result.id), access_token: access_token, conn: shared.conn)

            assert ~i(delete_response.successful)
          end
        end)

        [
          user:      [user: false, moderator: true,   admin: true],
          moderator: [user: false, moderator: false,  admin: true],
          admin:     [user: false, moderator: false,  admin: false],
        ] |> Enum.each(fn({user_role, cols}) ->
          cols |> Enum.each(fn({role, is_allowed}) ->
              it "#{if is_allowed, do: "allows", else: "does not allow"} #{role} to delete #{user_role}", permission: true, allow: is_allowed, role: user_role do
                user = build(unquote(user_role))
                author = build(:author)

                %{access_token: access_token} = creator()
                create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

                %{access_token: access_token} = unquote(:"creator_#{role}")()
                delete_response = delete_author(id: ~i(create_response.result.author.id), access_token: access_token, conn: shared.conn)

                if unquote(is_allowed) do
                  assert ~i(delete_response.successful)
                else
                  refute ~i(delete_response.successful)
                end
              end
          end)
        end)
      end
    end
  end
end
