defmodule Arkenston.Mutator.UserMutatorSpec do
  import Arkenston.Factories.MainFactory
  alias Arkenston.Subject
  alias Arkenston.Repo
  import Arkenston.Helper.UUID
  import SubjectHelper
  use GraphqlHelper
  import Faker.Internet, only: [slug: 0, email: 0]
  import Faker.Lorem, only: [word: 0, sentence: 0, characters: 1]
  use ESpec, async: true
  import Indifferent.Sigils

  let :valid_attrs do
    %{password: "not_null", role: :user}
  end

  let :creator_user do
    user = build(:user)
    author = build(:author)

    {:ok, result} = Subject.create_author(author)
    {:ok, result} = Subject.create_user(user |> Map.put(:author_id, result.id))

    result = result |> Repo.preload(:author)

    %{author: author, user: user, id: result.id, access_token: auth(user, author, shared.conn)}
  end

  let :creator_moderator do
    user = build(:moderator)
    author = build(:author)

    {:ok, result} = Subject.create_author(author)
    {:ok, result} = Subject.create_user(user |> Map.put(:author_id, result.id))

    result = result |> Repo.preload(:author)

    %{author: author, user: user, id: result.id, access_token: auth(user, author, shared.conn)}
  end

  let :creator_admin do
    user = build(:admin)
    author = build(:author)

    {:ok, result} = Subject.create_author(author)
    {:ok, result} = Subject.create_user(user |> Map.put(:author_id, result.id))

    result = result |> Repo.preload(:author)

    %{author: author, user: user, id: result.id, access_token: auth(user, author, shared.conn)}
  end

  let :creator_anonymous do
    nil
  end

  let :creator do
    creator_admin()
  end

  def role_genitive(:admin, :ru), do: "администратора"
  def role_genitive(:moderator, :ru), do: "модератора"
  def role_genitive(:user, :ru), do: "пользователя"
  def role_genitive(role, :en), do: to_string(role)

  context "mutator", module: :mutator, mutation: true do
    context "user", user: true do
      describe "createUser" do
        it "returns created user for valid attrs", validation: true, valid: true do
          user = build(:user)
          author = build(:author)

          create_response = create_user(input: prepare_user(user), author: prepare_author(author), conn: shared.conn)

          expect ~i(create_response.errors) |> to(be_nil())
          assert check_user(~i(create_response.data.createUser), prepare_user(user) |> Map.put(:author, author))
        end

        it "returns error for unknown author id", validation: true, valid: false do
          invalid_user = build(:user)
          create_response = create_user(input: prepare_user(invalid_user), author: %{id: domain_uuid(:author)}, conn: shared.conn)

          expect ~i(create_response.errors) |> not_to(be_empty())
        end

        [
          en: "User with the same author is already exist",
          ru: "Пользователь с аналогичным автором уже существует"
        ] |> Enum.each(fn {locale, msg} ->
          it "returns error for already used author id (#{locale})", validation: true, valid: false, locale: locale do
            existing_user = build(:user)
            existing_author = build(:author)
            author_response = create_user(input: prepare_user(existing_user), author: prepare_author(existing_author), conn: shared.conn)

            invalid_user = build(:user)
            create_response = create_user(input: prepare_user(invalid_user), author: %{id: ~i(author_response.data.createUser.author.id)}, conn: shared.conn, locale: unquote(locale))

            expect ~i(create_response.errors) |> not_to(be_empty())
            expect ~i(create_response.errors[0].operation) |> to(eq("createUser"))
            expect ~i(create_response.errors[0].entity) |> to(eq("user"))
            expect ~i(create_response.errors[0].code) |> to(eq("unique"))
            expect ~i(create_response.errors[0].field) |> to(eq("author"))
            expect ~i(create_response.errors[0].message) |> to(eq(unquote(msg)))
          end

          it "returns error for already used author name (#{locale})", validation: true, valid: false, locale: locale do
            existing_user = build(:user)
            existing_author = build(:author)
            create_user(input: prepare_user(existing_user), author: prepare_author(existing_author), conn: shared.conn)

            invalid_user = build(:user)
            create_response = create_user(input: prepare_user(invalid_user), author: %{name: existing_author.name |> String.upcase()}, conn: shared.conn, locale: unquote(locale))

            expect ~i(create_response.errors) |> not_to(be_empty())
            expect ~i(create_response.errors[0].operation) |> to(eq("createUser"))
            expect ~i(create_response.errors[0].entity) |> to(eq("user"))
            expect ~i(create_response.errors[0].code) |> to(eq("unique"))
            expect ~i(create_response.errors[0].field) |> to(eq("author"))
            expect ~i(create_response.errors[0].message) |> to(eq(unquote(msg)))
          end

          it "returns error for already used author email (#{locale})", validation: true, valid: false, locale: locale do
            existing_user = build(:user)
            existing_author = build(:author)
            create_user(input: prepare_user(existing_user), author: prepare_author(existing_author), conn: shared.conn)

            invalid_user = build(:user)
            create_response = create_user(input: prepare_user(invalid_user), author: %{email: existing_author.email |> String.upcase()}, conn: shared.conn, locale: unquote(locale))

            expect ~i(create_response.errors) |> not_to(be_empty())
            expect ~i(create_response.errors[0].operation) |> to(eq("createUser"))
            expect ~i(create_response.errors[0].entity) |> to(eq("user"))
            expect ~i(create_response.errors[0].code) |> to(eq("unique"))
            expect ~i(create_response.errors[0].field) |> to(eq("author"))
            expect ~i(create_response.errors[0].message) |> to(eq(unquote(msg)))
          end
        end)

        [
          en: "User name cannot be empty",
          ru: "Имя пользователя не может быть пустым"
        ] |> Enum.each(fn {locale, msg} ->
          it "returns error for empty author name (#{locale})", validation: true, valid: false, locale: locale do
            user = build(:user)
            author = build(:author)

            create_response = create_user(input: prepare_user(user), author: prepare_author(author) |> Map.drop([:name]), conn: shared.conn, locale: unquote(locale))
            expect ~i(create_response.errors) |> not_to(be_empty())
            expect ~i(create_response.errors[0].operation) |> to(eq("createUser"))
            expect ~i(create_response.errors[0].entity) |> to(eq("user"))
            expect ~i(create_response.errors[0].code) |> to(eq("required"))
            expect ~i(create_response.errors[0].field) |> to(eq("name"))
            expect ~i(create_response.errors[0].message) |> to(eq(unquote(msg)))

            create_response = create_user(input: prepare_user(user), author: prepare_author(author) |> Map.put(:name, nil), conn: shared.conn, locale: unquote(locale))
            expect ~i(create_response.errors) |> not_to(be_empty())
            expect ~i(create_response.errors[0].operation) |> to(eq("createUser"))
            expect ~i(create_response.errors[0].entity) |> to(eq("user"))
            expect ~i(create_response.errors[0].code) |> to(eq("required"))
            expect ~i(create_response.errors[0].field) |> to(eq("name"))
            expect ~i(create_response.errors[0].message) |> to(eq(unquote(msg)))
          end
        end)

        [
          en: "User name should be at least 3 characters long",
          ru: "Длина имени пользователя должна составлять минимум 3 символа"
        ] |> Enum.each(fn {locale, msg} ->
          it "returns error for too short author name (#{locale})", validation: true, valid: false, locale: locale do
            user = build(:user)
            author = build(:author)

            create_response = create_user(input: prepare_user(user), author: prepare_author(author) |> Map.put(:name, characters(1) |> to_string()), conn: shared.conn, locale: unquote(locale))
            expect ~i(create_response.errors) |> not_to(be_empty())
            expect ~i(create_response.errors[0].operation) |> to(eq("createUser"))
            expect ~i(create_response.errors[0].entity) |> to(eq("user"))
            expect ~i(create_response.errors[0].code) |> to(eq("min"))
            expect ~i(create_response.errors[0].field) |> to(eq("name"))
            expect ~i(create_response.errors[0].message) |> to(eq(unquote(msg)))

            create_response = create_user(input: prepare_user(user), author: prepare_author(author) |> Map.put(:name, characters(2) |> to_string()), conn: shared.conn, locale: unquote(locale))
            expect ~i(create_response.errors) |> not_to(be_empty())
            expect ~i(create_response.errors[0].operation) |> to(eq("createUser"))
            expect ~i(create_response.errors[0].entity) |> to(eq("user"))
            expect ~i(create_response.errors[0].code) |> to(eq("min"))
            expect ~i(create_response.errors[0].field) |> to(eq("name"))
            expect ~i(create_response.errors[0].message) |> to(eq(unquote(msg)))
          end
        end)

        [
          en: "User name %{name} has invalid format",
          ru: "Имя пользователя %{name} не соответствует формату"
        ] |> Enum.each(fn {locale, msg} ->
          it "returns error for invalid author name (#{locale})", validation: true, valid: false, locale: locale do
            user = build(:user)
            author = build(:author, name: "оШиБкА")

            create_response = create_user(input: prepare_user(user), author: prepare_author(author), conn: shared.conn, locale: unquote(locale))
            expect ~i(create_response.errors) |> not_to(be_empty())
            expect ~i(create_response.errors[0].operation) |> to(eq("createUser"))
            expect ~i(create_response.errors[0].entity) |> to(eq("user"))
            expect ~i(create_response.errors[0].code) |> to(eq("format"))
            expect ~i(create_response.errors[0].field) |> to(eq("name"))
            expect ~i(create_response.errors[0].message) |> to(eq(unquote(msg) |> String.replace("%{name}", String.downcase(author.name))))
          end
        end)

        [
          en: "User email cannot be empty",
          ru: "Email пользователя не может быть пустым"
        ] |> Enum.each(fn {locale, msg} ->
          it "returns error without author email (#{locale})", validation: true, valid: false, locale: locale do
            user = build(:user)
            author = build(:author)

            create_response = create_user(input: prepare_user(user), author: prepare_author(author) |> Map.drop([:email]), conn: shared.conn, locale: unquote(locale))
            expect ~i(create_response.errors) |> not_to(be_empty())
            expect ~i(create_response.errors[0].operation) |> to(eq("createUser"))
            expect ~i(create_response.errors[0].entity) |> to(eq("user"))
            expect ~i(create_response.errors[0].code) |> to(eq("required"))
            expect ~i(create_response.errors[0].field) |> to(eq("email"))
            expect ~i(create_response.errors[0].message) |> to(eq(unquote(msg)))
          end

          it "returns error for nil author email (#{locale})", validation: true, valid: false, locale: locale do
            user = build(:user)
            author = build(:author)

            create_response = create_user(input: prepare_user(user), author: prepare_author(author) |> Map.put(:email, nil), conn: shared.conn, locale: unquote(locale))
            expect ~i(create_response.errors) |> not_to(be_empty())
            expect ~i(create_response.errors[0].operation) |> to(eq("createUser"))
            expect ~i(create_response.errors[0].entity) |> to(eq("user"))
            expect ~i(create_response.errors[0].code) |> to(eq("required"))
            expect ~i(create_response.errors[0].field) |> to(eq("email"))
            expect ~i(create_response.errors[0].message) |> to(eq(unquote(msg)))
          end

          it "returns error for empty author email (#{locale})", validation: true, valid: false, locale: locale do
            user = build(:user)
            author = build(:author)

            create_response = create_user(input: prepare_user(user), author: prepare_author(author) |> Map.put(:email, ""), conn: shared.conn, locale: unquote(locale))
            expect ~i(create_response.errors) |> not_to(be_empty())
            expect ~i(create_response.errors[0].operation) |> to(eq("createUser"))
            expect ~i(create_response.errors[0].entity) |> to(eq("user"))
            expect ~i(create_response.errors[0].code) |> to(eq("required"))
            expect ~i(create_response.errors[0].field) |> to(eq("email"))
            expect ~i(create_response.errors[0].message) |> to(eq(unquote(msg)))
          end
        end)

        [
          en: "User email %{email} has invalid format",
          ru: "Email пользователя %{email} не соответствует формату"
        ] |> Enum.each(fn {locale, msg} ->
          it "returns error for invalid author email (#{locale})", validation: true, valid: false, locale: locale do
            user = build(:user)
            author = build(:author, email: word())

            create_response = create_user(input: prepare_user(user), author: prepare_author(author), conn: shared.conn, locale: unquote(locale))
            expect ~i(create_response.errors) |> not_to(be_empty())
            expect ~i(create_response.errors[0].operation) |> to(eq("createUser"))
            expect ~i(create_response.errors[0].entity) |> to(eq("user"))
            expect ~i(create_response.errors[0].code) |> to(eq("format"))
            expect ~i(create_response.errors[0].field) |> to(eq("email"))
            expect ~i(create_response.errors[0].message) |> to(eq(unquote(msg) |> String.replace("%{email}", String.downcase(author.email))))
          end
        end)

        [
          en: "Password cannot be empty",
          ru: "Пароль не может быть пустым"
        ] |> Enum.each(fn {locale, msg} ->
          it "returns error for empty password (#{locale})", validation: true, valid: false, locale: locale do
            user = build(:user)
            author = build(:author)

            create_response = create_user(input: prepare_user(user) |> Map.put(:password, ""), author: prepare_author(author), conn: shared.conn, locale: unquote(locale))
            expect ~i(create_response.errors) |> not_to(be_empty())
            expect ~i(create_response.errors[0].operation) |> to(eq("createUser"))
            expect ~i(create_response.errors[0].entity) |> to(eq("user"))
            expect ~i(create_response.errors[0].code) |> to(eq("required"))
            expect ~i(create_response.errors[0].field) |> to(eq("password"))
            expect ~i(create_response.errors[0].message) |> to(eq(unquote(msg)))

            create_response = create_user(input: prepare_user(user) |> Map.put(:password, nil), author: prepare_author(author), conn: shared.conn, locale: unquote(locale))
            expect ~i(create_response.errors) |> not_to(be_empty())
          end
        end)

        [
          en: "Password should be at least 6 characters long",
          ru: "Длина пароля должна составлять минимум 6 символов"
        ] |> Enum.each(fn {locale, msg} ->
          it "returns error for too short password (#{locale})", validation: true, valid: false, locale: locale do
            user = build(:user)
            author = build(:author)

            create_response = create_user(input: prepare_user(user) |> Map.put(:password, characters(1) |> to_string()), author: prepare_author(author), conn: shared.conn, locale: unquote(locale))
            expect ~i(create_response.errors) |> not_to(be_empty())
            expect ~i(create_response.errors[0].operation) |> to(eq("createUser"))
            expect ~i(create_response.errors[0].entity) |> to(eq("user"))
            expect ~i(create_response.errors[0].code) |> to(eq("min"))
            expect ~i(create_response.errors[0].field) |> to(eq("password"))
            expect ~i(create_response.errors[0].message) |> to(eq(unquote(msg)))

            create_response = create_user(input: prepare_user(user) |> Map.put(:password, characters(5) |> to_string()), author: prepare_author(author), conn: shared.conn, locale: unquote(locale))
            expect ~i(create_response.errors) |> not_to(be_empty())
            expect ~i(create_response.errors[0].operation) |> to(eq("createUser"))
            expect ~i(create_response.errors[0].entity) |> to(eq("user"))
            expect ~i(create_response.errors[0].code) |> to(eq("min"))
            expect ~i(create_response.errors[0].field) |> to(eq("password"))
            expect ~i(create_response.errors[0].message) |> to(eq(unquote(msg)))
          end
        end)

        it "accepts note for revision", audit: true do
          user = build(:user)
          author = build(:author)

          note = sentence()
          create_response = create_user(input: prepare_user(user) |> Map.merge(%{note: note}), author: prepare_author(author), conn: shared.conn)
          expect ~i(create_response.data.createUser.note) |> to(eq(note))
        end

        it "sets revision version to 1", audit: true do
          user = build(:user)
          author = build(:author)

          create_response = create_user(input: prepare_user(user), author: prepare_author(author), conn: shared.conn)

          expect ~i(create_response.data.createUser.version) |> to(eq(1))
        end

        it "sets created_by to non-nil if context is not empty", audit: true do
          user = build(:user)
          author = build(:author)

          %{access_token: access_token, id: creator_id} = creator()
          create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

          expect ~i(create_response.data.createUser.created_by.id) |> to(eq(creator_id))
        end

        it "sets created_by to nil if context is empty", audit: true, role: :anonymous do
          user = build(:user)
          author = build(:author)

          create_response = create_user(input: prepare_user(user), author: prepare_author(author), conn: shared.conn)

          expect ~i(create_response.data.createUser.created_by) |> to(be_nil())
        end

        it "sets created_at", audit: true do
          user = build(:user)
          author = build(:author)

          create_response = create_user(input: prepare_user(user), author: prepare_author(author), conn: shared.conn)

          expect ~i(create_response.data.createUser.created_at) |> not_to(be_nil())
        end

        [
          en: "Not enough permissions to create user with role %{role}",
          ru: "Недостаточно прав для создания пользователя с ролью %{role}"
        ] |> Enum.each(fn {locale, msg} ->
          [
            user:      [anonymous: true,  user: false, moderator: true,  admin: true],
            moderator: [anonymous: false, user: false, moderator: true,  admin: true],
            admin:     [anonymous: false, user: false, moderator: false, admin: true],
          ] |> Enum.each(fn({user_role, cols}) ->
            cols |> Enum.each(fn({role, is_allowed}) ->
                it "#{if is_allowed, do: "allows", else: "does not allow"} to create new #{user_role} by #{role} (#{locale})", permission: true, allow: is_allowed, role: role, locale: locale do
                  user = build(unquote(user_role))
                  author = build(:author)

                  create_response = if unquote(role) == :anonymous do
                    create_user(input: prepare_user(user), author: prepare_author(author), conn: shared.conn, locale: unquote(locale))
                  else
                    %{access_token: access_token} = unquote(:"creator_#{role}")()
                    create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn, locale: unquote(locale))
                  end

                  if unquote(is_allowed) do
                    expect ~i(create_response.errors) |> to(be_nil())
                  else
                    expect ~i(create_response.errors) |> not_to(be_empty())
                    expect ~i(create_response.errors[0].operation) |> to(eq("createUser"))
                    expect ~i(create_response.errors[0].entity) |> to(eq("user"))
                    expect ~i(create_response.errors[0].code) |> to(eq("permissions"))
                    expect ~i(create_response.errors[0].field) |> to(eq("role"))
                    expect ~i(create_response.errors[0].message) |> to(eq(unquote(msg) |> String.replace("%{role}", role_genitive(unquote(user_role), unquote(locale)))))
                  end
                end
            end)
          end)
        end)

        [
          en: "Not enough permissions to create user with role %{role}",
          ru: "Недостаточно прав для создания пользователя с ролью %{role}"
        ] |> Enum.each(fn {locale, msg} ->
          [
            user:      [user: false, moderator: true,  admin: true],
            moderator: [user: false, moderator: true,  admin: true],
            admin:     [user: false, moderator: false, admin: true],
          ] |> Enum.each(fn({user_role, cols}) ->
            cols |> Enum.each(fn({role, is_allowed}) ->
                it "#{if is_allowed, do: "allows", else: "does not allow"} to create new #{user_role} with custom author by #{role} (#{locale})", permission: true, allow: is_allowed, role: role, locale: locale do
                  author = build(:author)
                  %{access_token: access_token} = creator()
                  create_author_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

                  user = build(unquote(user_role))
                  %{access_token: access_token} = unquote(:"creator_#{role}")()
                  create_response = create_user(input: prepare_user(user), author: %{id: ~i(create_author_response.data.createAuthor.id)}, access_token: access_token, conn: shared.conn, locale: unquote(locale))

                  if unquote(is_allowed) do
                    expect ~i(create_response.errors) |> to(be_nil())
                  else
                    expect ~i(create_response.errors) |> not_to(be_empty())
                    expect ~i(create_response.errors[0].operation) |> to(eq("createUser"))
                    expect ~i(create_response.errors[0].entity) |> to(eq("user"))
                    expect ~i(create_response.errors[0].code) |> to(eq("permissions"))
                    expect ~i(create_response.errors[0].field) |> to(eq("role"))
                    expect ~i(create_response.errors[0].message) |> to(eq(unquote(msg) |> String.replace("%{role}", role_genitive(unquote(user_role), unquote(locale)))))
                  end
                end
            end)
          end)
        end)
      end

      describe "updateUser" do
        it "returns success for valid id", validation: true, valid: true do
          user = build(:user)
          author = build(:author)

          %{access_token: access_token} = creator()
          create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

          update_response = update_user(id: ~i(create_response.data.createUser.id), input: prepare_user(valid_attrs()), access_token: access_token, conn: shared.conn)

          expect ~i(update_response.errors) |> to(be_nil())

          expected_user = prepare_user(user) |> Map.merge(valid_attrs()) |> Map.put(:author, author)
          assert check_user(~i(update_response.data.updateUser), expected_user)
        end

        it "returns success for valid name", validation: true, valid: true do
          user = build(:user)
          author = build(:author)

          %{access_token: access_token} = creator()
          create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

          update_response = update_user(name: author.name |> String.upcase(), input: prepare_user(valid_attrs()), access_token: access_token, conn: shared.conn)

          expect ~i(update_response.errors) |> to(be_nil())

          expected_user = prepare_user(user) |> Map.merge(valid_attrs()) |> Map.put(:author, author)
          assert check_user(~i(update_response.data.updateUser), expected_user)
        end

        it "returns success for valid email", validation: true, valid: true do
          user = build(:user)
          author = build(:author)

          %{access_token: access_token} = creator()
          create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

          update_response = update_user(email: author.email |> String.upcase(), input: prepare_user(valid_attrs()), access_token: access_token, conn: shared.conn)

          expect ~i(update_response.errors) |> to(be_nil())

          expected_user = prepare_user(user) |> Map.merge(valid_attrs()) |> Map.put(:author, author)
          assert check_user(~i(update_response.data.updateUser), expected_user)
        end

        it "returns success for current user", validation: true, valid: true do
          user = build(:user)
          author = build(:author)

          %{access_token: access_token} = creator()
          create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

          access_token = auth(user, author, shared.conn)
          update_response = update_user(input: prepare_user(valid_attrs()), access_token: access_token, conn: shared.conn)

          expect ~i(update_response.errors) |> to(be_nil())
          expected_user = prepare_user(user) |> Map.merge(valid_attrs()) |> Map.put(:author, author)
          assert check_user(~i(update_response.data.updateUser), expected_user)
        end

        [
          en: "Cannot find user with specified id",
          ru: "Пользователь с указанным id не найден"
        ] |> Enum.each(fn {locale, msg} ->
          it "returns error for unknown id (#{locale})", validation: true, valid: false, locale: locale do
            %{access_token: access_token} = creator()
            update_response = update_user(id: domain_uuid(:user), input: prepare_user(valid_attrs()), access_token: access_token, conn: shared.conn, locale: unquote(locale))

            expect ~i(update_response.errors) |> not_to(be_empty())
            expect ~i(update_response.errors[0].operation) |> to(eq("updateUser"))
            expect ~i(update_response.errors[0].entity) |> to(eq("user"))
            expect ~i(update_response.errors[0].code) |> to(eq("missing"))
            expect ~i(update_response.errors[0].field) |> to(eq("id"))
            expect ~i(update_response.errors[0].message) |> to(eq(unquote(msg)))
          end
        end)

        [
          en: "Cannot find user with specified name",
          ru: "Пользователь с указанным именем не найден"
        ] |> Enum.each(fn {locale, msg} ->
          it "returns error for unknown name (#{locale})", validation: true, valid: true, locale: locale do
            author = build(:author)

            %{access_token: access_token} = creator()

            update_response = update_user(name: author.name |> String.upcase(), input: prepare_user(valid_attrs()), access_token: access_token, conn: shared.conn, locale: unquote(locale))

            expect ~i(update_response.errors) |> not_to(be_empty())
            expect ~i(update_response.errors[0].operation) |> to(eq("updateUser"))
            expect ~i(update_response.errors[0].entity) |> to(eq("user"))
            expect ~i(update_response.errors[0].code) |> to(eq("missing"))
            expect ~i(update_response.errors[0].field) |> to(eq("name"))
            expect ~i(update_response.errors[0].message) |> to(eq(unquote(msg)))
          end
        end)

        [
          en: "Cannot find user with specified email",
          ru: "Пользователь с указанным email не найден"
        ] |> Enum.each(fn {locale, msg} ->
          it "returns error for unknown email (#{locale})", validation: true, valid: true, locale: locale do
            author = build(:author)

            %{access_token: access_token} = creator()

            update_response = update_user(email: author.email |> String.upcase(), input: prepare_user(valid_attrs()), access_token: access_token, conn: shared.conn, locale: unquote(locale))

            expect ~i(update_response.errors) |> not_to(be_empty())
            expect ~i(update_response.errors[0].operation) |> to(eq("updateUser"))
            expect ~i(update_response.errors[0].entity) |> to(eq("user"))
            expect ~i(update_response.errors[0].code) |> to(eq("missing"))
            expect ~i(update_response.errors[0].field) |> to(eq("email"))
            expect ~i(update_response.errors[0].message) |> to(eq(unquote(msg)))
          end
        end)

        [
          en: "Password should be at least 6 characters long",
          ru: "Длина пароля должна составлять минимум 6 символов"
        ] |> Enum.each(fn {locale, msg} ->
          it "returns error for too short password (#{locale})", validation: true, valid: false, locale: locale do
            user = build(:user)
            author = build(:author)

            %{access_token: access_token} = creator()
            create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

            update_response = update_user(id: ~i(create_response.data.createUser.id), input: %{password: characters(1) |> to_string()}, access_token: access_token, conn: shared.conn, locale: unquote(locale))
            expect ~i(update_response.errors) |> not_to(be_empty())
            expect ~i(update_response.errors[0].operation) |> to(eq("updateUser"))
            expect ~i(update_response.errors[0].entity) |> to(eq("user"))
            expect ~i(update_response.errors[0].code) |> to(eq("min"))
            expect ~i(update_response.errors[0].field) |> to(eq("password"))
            expect ~i(update_response.errors[0].message) |> to(eq(unquote(msg)))

            update_response = update_user(id: ~i(create_response.data.createUser.id), input: %{password: characters(5) |> to_string()}, access_token: access_token, conn: shared.conn, locale: unquote(locale))
            expect ~i(update_response.errors) |> not_to(be_empty())
            expect ~i(update_response.errors[0].operation) |> to(eq("updateUser"))
            expect ~i(update_response.errors[0].entity) |> to(eq("user"))
            expect ~i(update_response.errors[0].code) |> to(eq("min"))
            expect ~i(update_response.errors[0].field) |> to(eq("password"))
            expect ~i(update_response.errors[0].message) |> to(eq(unquote(msg)))
          end
        end)

        [
          en: "Not enough permissions to update user",
          ru: "Недостаточно прав для обновления пользователя"
        ] |> Enum.each(fn {locale, msg} ->
          it "returns error for anonymous user (#{locale})", validation: true, valid: false, locale: locale do
            user = build(:user)
            author = build(:author)

            %{access_token: access_token} = creator()
            create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

            update_response = update_user(id: ~i(create_response.data.createUser.id), input: %{note: characters(6) |> to_string()}, conn: shared.conn, locale: unquote(locale))

            expect ~i(update_response.errors) |> not_to(be_empty())
            expect ~i(update_response.errors[0].operation) |> to(eq("updateUser"))
            expect ~i(update_response.errors[0].entity) |> to(eq("user"))
            expect ~i(update_response.errors[0].code) |> to(eq("permissions"))
            expect ~i(update_response.errors[0].field) |> to(be_nil())
            expect ~i(update_response.errors[0].message) |> to(eq(unquote(msg)))
          end
        end)

        [
          en: "Cannot find user with specified id",
          ru: "Пользователь с указанным id не найден"
        ] |> Enum.each(fn {locale, msg} ->
          it "returns error for already deleted user", validation: true, valid: false do
            user = build(:user)
            author = build(:author)

            %{access_token: access_token} = creator()
            create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)
            delete_user(id: ~i(create_response.data.createUser.id), access_token: access_token, conn: shared.conn)

            update_response = update_user(id: ~i(create_response.data.createUser.id), input: prepare_user(valid_attrs()), access_token: access_token, conn: shared.conn, locale: unquote(locale))

            expect ~i(update_response.errors) |> not_to(be_empty())
            expect ~i(update_response.errors[0].operation) |> to(eq("updateUser"))
            expect ~i(update_response.errors[0].entity) |> to(eq("user"))
            expect ~i(update_response.errors[0].code) |> to(eq("missing"))
            expect ~i(update_response.errors[0].field) |> to(eq("id"))
            expect ~i(update_response.errors[0].message) |> to(eq(unquote(msg)))
          end
        end)

        it "accepts note for revision", audit: true do
          user = build(:user)
          author = build(:author)

          %{access_token: access_token} = creator()
          create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

          note = sentence()
          update_response = update_user(id: ~i(create_response.data.createUser.id), input: %{note: note}, access_token: access_token, conn: shared.conn)

          expect ~i(update_response.data.updateUser.note) |> to(eq(note))
        end

        it "increments revision version", audit: true do
          user = build(:user)
          author = build(:author)

          %{access_token: access_token} = creator()
          create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)
          update_response = update_user(id: ~i(create_response.data.createUser.id), input: prepare_user(valid_attrs()), access_token: access_token, conn: shared.conn)

          expect ~i(update_response.data.updateUser.version) |> to(be(:>, ~i(create_response.data.createUser.version)))
        end

        it "sets updated_by to non-nil if context is not empty", audit: true do
          user = build(:user)
          author = build(:author)

          %{access_token: access_token, id: updator_id} = creator()
          create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)
          update_response = update_user(id: ~i(create_response.data.createUser.id), input: prepare_user(valid_attrs()), access_token: access_token, conn: shared.conn)

          expect ~i(update_response.data.updateUser.updated_by.id) |> to(eq(updator_id))
        end

        it "does not touch created_at", audit: true do
          user = build(:user)
          author = build(:author)

          %{access_token: access_token} = creator()
          create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)
          update_response = update_user(id: ~i(create_response.data.createUser.id), input: prepare_user(valid_attrs()), access_token: access_token, conn: shared.conn)

          expect ~i(update_response.data.updateUser.created_at) |> to(eq(~i(create_response.data.createUser.created_at)))
        end

        it "touches updated_at", audit: true do
          user = build(:user)
          author = build(:author)

          %{access_token: access_token} = creator()
          create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)
          update_response = update_user(id: ~i(create_response.data.createUser.id), input: prepare_user(valid_attrs()), access_token: access_token, conn: shared.conn)

          expect ~i(create_response.data.createUser.updated_at) |> to(be_nil())
          expect ~i(update_response.data.updateUser.updated_at) |> not_to(be_nil())
        end

        [:user, :moderator, :admin]
        |> Enum.each(fn(user_role) ->
          it "allows #{user_role} to update himself", permission: true, allow: true, self: true do
            user = build(unquote(user_role))
            author = build(:author)

            %{access_token: access_token} = creator()
            create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

            note = word()
            access_token = auth(user, author, shared.conn)
            update_response = update_user(id: ~i(create_response.data.createUser.id), input: %{note: note}, access_token: access_token, conn: shared.conn)

            expect ~i(update_response.errors) |> to(be_nil())
          end
        end)

        [
          en: "Not enough permissions to update user",
          ru: "Недостаточно прав для обновления пользователя"
        ] |> Enum.each(fn {locale, msg} ->
          [
            user:      [user: false, moderator: true,  admin: true],
            moderator: [user: false, moderator: true,  admin: true],
            admin:     [user: false, moderator: false, admin: true],
          ] |> Enum.each(fn({user_role, cols}) ->
            cols |> Enum.each(fn({role, is_allowed}) ->
                it "#{if is_allowed, do: "allows", else: "does not allow"} #{role} to update #{user_role} (#{locale})", permission: true, allow: is_allowed, role: user_role, locale: locale do
                  user = build(unquote(user_role))
                  author = build(:author)

                  %{access_token: access_token} = creator()
                  create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

                  note = word()
                  %{access_token: access_token} = unquote(:"creator_#{role}")()
                  update_response = update_user(id: ~i(create_response.data.createUser.id), input: %{note: note}, access_token: access_token, conn: shared.conn, locale: unquote(locale))

                  if unquote(is_allowed) do
                    expect ~i(update_response.errors) |> to(be_nil())
                  else
                    expect ~i(update_response.errors) |> not_to(be_empty())
                    expect ~i(update_response.errors[0].operation) |> to(eq("updateUser"))
                    expect ~i(update_response.errors[0].entity) |> to(eq("user"))
                    expect ~i(update_response.errors[0].code) |> to(eq("permissions"))
                    expect ~i(update_response.errors[0].field) |> to(be_nil())
                    expect ~i(update_response.errors[0].message) |> to(eq(unquote(msg)))
                  end
                end
            end)
          end)
        end)

        [:user, :moderator, :admin]
        |> Enum.each(fn(user_role) ->
          it "allows to change #{user_role} password by himself", permission: true, allow: true, self: true do
            user = build(unquote(user_role))
            author = build(:author)

            %{access_token: access_token} = creator()
            create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

            password = characters(6) |> to_string()
            access_token = auth(user, author, shared.conn)
            update_response = update_user(id: ~i(create_response.data.createUser.id), input: %{password: password}, access_token: access_token, conn: shared.conn)

            expect ~i(update_response.errors) |> to(be_nil())
          end
        end)

        [
          en: "Not enough permissions to update user",
          ru: "Недостаточно прав для обновления пользователя"
        ] |> Enum.each(fn {locale, msg} ->
          [
            user:      [user: false, moderator: true,  admin: true],
            moderator: [user: false, moderator: false, admin: true],
            admin:     [user: false, moderator: false, admin: false],
          ] |> Enum.each(fn({user_role, cols}) ->
            cols |> Enum.each(fn({role, is_allowed}) ->
              it "#{if is_allowed, do: "allows", else: "does not allow"} #{role} to change #{user_role} password (#{locale})", permission: true, allow: is_allowed, role: role, locale: locale do
                user = build(unquote(user_role))
                author = build(:author)

                %{access_token: access_token} = creator()
                create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

                password = characters(6) |> to_string()
                %{access_token: access_token} = unquote(:"creator_#{role}")()
                update_response = update_user(id: ~i(create_response.data.createUser.id), input: %{password: password}, access_token: access_token, conn: shared.conn, locale: unquote(locale))

                if unquote(is_allowed) do
                  expect ~i(update_response.errors) |> to(be_nil())
                else
                  expect ~i(update_response.errors) |> not_to(be_empty())
                  expect ~i(update_response.errors[0].operation) |> to(eq("updateUser"))
                  expect ~i(update_response.errors[0].entity) |> to(eq("user"))
                  expect ~i(update_response.errors[0].code) |> to(eq("permissions"))
                  expect ~i(update_response.errors[0].field) |> to(be_nil())
                  expect ~i(update_response.errors[0].message) |> to(eq(unquote(msg)))
                end
              end
            end)
          end)
        end)

        [
          en: "Not enough permissions to update user with role %{role}",
          ru: "Недостаточно прав для обновления пользователя с ролью %{role}"
        ] |> Enum.each(fn {locale, msg} ->
          [
            user: [:moderator, :admin],
            moderator: [:admin]
          ] |> Enum.each(fn({user_role, roles}) ->
            roles |> Enum.each(fn(target_role) ->
              it "does not allow #{user_role} to upgrade his role to #{target_role} (#{locale})", permission: true, allow: false, self: true, locale: locale do
                user = build(unquote(user_role))
                author = build(:author)

                %{access_token: access_token} = creator()
                create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

                access_token = auth(user, author, shared.conn)
                update_response = update_user(id: ~i(create_response.data.createUser.id), input: prepare_user(%{role: unquote(target_role)}), access_token: access_token, conn: shared.conn, locale: unquote(locale))

                expect ~i(update_response.errors) |> not_to(be_empty())
                expect ~i(update_response.errors[0].operation) |> to(eq("updateUser"))
                expect ~i(update_response.errors[0].entity) |> to(eq("user"))
                expect ~i(update_response.errors[0].code) |> to(eq("permissions"))
                expect ~i(update_response.errors[0].field) |> to(eq("role"))
                expect ~i(update_response.errors[0].message) |> to(eq(unquote(msg) |> String.replace("%{role}", role_genitive(unquote(target_role), unquote(locale)))))
              end
            end)
          end)
        end)

        [
          en: "Not enough permissions to update user with role %{role}",
          ru: "Недостаточно прав для обновления пользователя с ролью %{role}"
        ] |> Enum.each(fn {locale, msg} ->
          [
            user: [
              moderator: [user: false, moderator: true,  admin: true],
              admin:     [user: false, moderator: false, admin: true],
            ],
            moderator: [
              admin:     [user: false, moderator: false, admin: true],
            ]
          ] |> Enum.each(fn({user_role, cols}) ->
            cols |> Enum.each(fn({target_role, col}) ->
              col |> Enum.each(fn({role, is_allowed}) ->
                it "#{if is_allowed, do: "allows", else: "does not allow"} #{role} to upgrade #{user_role} to #{target_role} (#{locale})", permission: true, allow: is_allowed, role: role, locale: locale do
                  user = build(unquote(user_role))
                  author = build(:author)

                  %{access_token: access_token} = creator()
                  create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

                  %{access_token: access_token} = unquote(:"creator_#{role}")()
                  update_response = update_user(id: ~i(create_response.data.createUser.id), input: prepare_user(%{role: unquote(target_role)}), access_token: access_token, conn: shared.conn, locale: unquote(locale))

                  if unquote(is_allowed) do
                    expect ~i(update_response.errors) |> to(be_nil())
                  else
                    expect ~i(update_response.errors) |> not_to(be_empty())
                    expect ~i(update_response.errors[0].operation) |> to(eq("updateUser"))
                    expect ~i(update_response.errors[0].entity) |> to(eq("user"))
                    expect ~i(update_response.errors[0].code) |> to(eq("permissions"))
                    expect ~i(update_response.errors[0].field) |> to(eq("role"))
                    expect ~i(update_response.errors[0].message) |> to(eq(unquote(msg) |> String.replace("%{role}", role_genitive(unquote(target_role), unquote(locale)))))
                  end
                end
              end)
            end)
          end)
        end)

        [
          en: "Not enough permissions to update user with role %{role}",
          ru: "Недостаточно прав для обновления пользователя с ролью %{role}"
        ] |> Enum.each(fn {locale, msg} ->
          [
            moderator: [:user],
            admin: [:user, :moderator]
          ] |> Enum.each(fn({user_role, target_roles}) ->
            target_roles |> Enum.each(fn(target_role) ->
              it "does not allow #{user_role} to downgrade his role to #{target_role} (#{locale})", permission: true, allow: false, self: true, locale: locale do
                user = build(unquote(user_role))
                author = build(:author)

                %{access_token: access_token} = creator()
                create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

                access_token = auth(user, author, shared.conn)
                update_response = update_user(id: ~i(create_response.data.createUser.id), input: prepare_user(%{role: unquote(target_role)}), access_token: access_token, conn: shared.conn, locale: unquote(locale))

                expect ~i(update_response.errors) |> not_to(be_empty())
                expect ~i(update_response.errors[0].operation) |> to(eq("updateUser"))
                expect ~i(update_response.errors[0].entity) |> to(eq("user"))
                expect ~i(update_response.errors[0].code) |> to(eq("permissions"))
                expect ~i(update_response.errors[0].field) |> to(eq("role"))
                expect ~i(update_response.errors[0].message) |> to(eq(unquote(msg) |> String.replace("%{role}", role_genitive(unquote(target_role), unquote(locale)))))
              end
            end)
          end)
        end)

        [
          en: "Not enough permissions to update user with role %{role}",
          ru: "Недостаточно прав для обновления пользователя с ролью %{role}"
        ] |> Enum.each(fn {locale, msg} ->
          [
            moderator: [
              user:      [user: false, moderator: false, admin: true],
            ],
            admin: [
              user:      [user: false, moderator: false, admin: false],
              moderator: [user: false, moderator: false, admin: false],
            ]
          ] |> Enum.each(fn({user_role, cols}) ->
            cols |> Enum.each(fn({target_role, col}) ->
              col |> Enum.each(fn({role, is_allowed}) ->
                it "#{if is_allowed, do: "allows", else: "does not allow"} #{role} to downgrade #{user_role} to #{target_role} (#{locale})", permission: true, allow: is_allowed, role: user_role, locale: locale do
                  user = build(unquote(user_role))
                  author = build(:author)

                  %{access_token: access_token} = creator()
                  create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

                  %{access_token: access_token} = unquote(:"creator_#{role}")()
                  update_response = update_user(id: ~i(create_response.data.createUser.id), input: prepare_user(%{role: unquote(target_role)}), access_token: access_token, conn: shared.conn, locale: unquote(locale))

                  if unquote(is_allowed) do
                    expect ~i(update_response.errors) |> to(be_nil())
                  else
                    expect ~i(update_response.errors) |> not_to(be_empty())
                    expect ~i(update_response.errors[0].operation) |> to(eq("updateUser"))
                    expect ~i(update_response.errors[0].entity) |> to(eq("user"))
                    expect ~i(update_response.errors[0].code) |> to(eq("permissions"))
                    expect ~i(update_response.errors[0].field) |> to(eq("role"))
                    expect ~i(update_response.errors[0].message) |> to(eq(unquote(msg) |> String.replace("%{role}", role_genitive(unquote(target_role), unquote(locale)))))
                  end
                end
              end)
            end)
          end)
        end)
      end

      describe "changeUserAuthor" do
        it "returns success for valid user id", validation: true, valid: true do
          existing_user = build(:user)
          existing_author = build(:author)

          %{access_token: access_token} = creator()
          create_user_response = create_user(input: prepare_user(existing_user), author: prepare_author(existing_author), access_token: access_token, conn: shared.conn)

          author = build(:author)
          create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

          change_user_author_response = change_user_author(id: ~i(create_user_response.data.createUser.id), author: %{id: ~i(create_response.data.createAuthor.id)}, access_token: access_token, conn: shared.conn)

          expect ~i(change_user_author_response.errors) |> to(be_nil())
          assert check_author(~i(change_user_author_response.data.changeUserAuthor.author), ~i(create_response.data.createAuthor))
        end

        it "returns success for valid user name", validation: true, valid: true do
          existing_user = build(:user)
          existing_author = build(:author)

          %{access_token: access_token} = creator()
          create_user(input: prepare_user(existing_user), author: prepare_author(existing_author), access_token: access_token, conn: shared.conn)

          author = build(:author)
          create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

          change_user_author_response = change_user_author(name: existing_author.name |> String.upcase(), author: %{id: ~i(create_response.data.createAuthor.id)}, access_token: access_token, conn: shared.conn)

          expect ~i(change_user_author_response.errors) |> to(be_nil())
          assert check_author(~i(change_user_author_response.data.changeUserAuthor.author), ~i(create_response.data.createAuthor))
        end

        it "returns success for valid user email", validation: true, valid: true do
          existing_user = build(:user)
          existing_author = build(:author)

          %{access_token: access_token} = creator()
          create_user(input: prepare_user(existing_user), author: prepare_author(existing_author), access_token: access_token, conn: shared.conn)

          author = build(:author)
          create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

          change_user_author_response = change_user_author(email: existing_author.email |> String.upcase(), author: %{id: ~i(create_response.data.createAuthor.id)}, access_token: access_token, conn: shared.conn)

          expect ~i(change_user_author_response.errors) |> to(be_nil())
          assert check_author(~i(change_user_author_response.data.changeUserAuthor.author), ~i(create_response.data.createAuthor))
        end

        [
          en: "Cannot find user with specified id",
          ru: "Пользователь с указанным id не найден"
        ] |> Enum.each(fn {locale, msg} ->
          it "returns error for unknown user id (#{locale})", validation: true, valid: false, locale: locale do
            author = build(:author)
            %{access_token: access_token} = creator()
            create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

            change_user_author_response = change_user_author(id: domain_uuid(:user), author: %{id: ~i(create_response.data.createAuthor.id)}, access_token: access_token, conn: shared.conn, locale: unquote(locale))

            expect ~i(change_user_author_response.errors) |> not_to(be_empty())
            expect ~i(change_user_author_response.errors[0].operation) |> to(eq("changeUserAuthor"))
            expect ~i(change_user_author_response.errors[0].entity) |> to(eq("user"))
            expect ~i(change_user_author_response.errors[0].code) |> to(eq("missing"))
            expect ~i(change_user_author_response.errors[0].field) |> to(eq("id"))
            expect ~i(change_user_author_response.errors[0].message) |> to(eq(unquote(msg)))
          end
        end)

        [
          en: "Cannot find user with specified name",
          ru: "Пользователь с указанным именем не найден"
        ] |> Enum.each(fn {locale, msg} ->
          it "returns error for unknown user name (#{locale})", validation: true, valid: false, locale: locale do
            author = build(:author)
            %{access_token: access_token} = creator()
            create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

            change_user_author_response = change_user_author(name: slug(), author: %{id: ~i(create_response.data.createAuthor.id)}, access_token: access_token, conn: shared.conn, locale: unquote(locale))

            expect ~i(change_user_author_response.errors) |> not_to(be_empty())
            expect ~i(change_user_author_response.errors[0].operation) |> to(eq("changeUserAuthor"))
            expect ~i(change_user_author_response.errors[0].entity) |> to(eq("user"))
            expect ~i(change_user_author_response.errors[0].code) |> to(eq("missing"))
            expect ~i(change_user_author_response.errors[0].field) |> to(eq("name"))
            expect ~i(change_user_author_response.errors[0].message) |> to(eq(unquote(msg)))
          end
        end)

        [
          en: "Cannot find user with specified email",
          ru: "Пользователь с указанным email не найден"
        ] |> Enum.each(fn {locale, msg} ->
          it "returns error for unknown user email (#{locale})", validation: true, valid: false, locale: locale do
            author = build(:author)
            %{access_token: access_token} = creator()
            create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

            change_user_author_response = change_user_author(email: slug(), author: %{id: ~i(create_response.data.createAuthor.id)}, access_token: access_token, conn: shared.conn, locale: unquote(locale))

            expect ~i(change_user_author_response.errors) |> not_to(be_empty())
            expect ~i(change_user_author_response.errors[0].operation) |> to(eq("changeUserAuthor"))
            expect ~i(change_user_author_response.errors[0].entity) |> to(eq("user"))
            expect ~i(change_user_author_response.errors[0].code) |> to(eq("missing"))
            expect ~i(change_user_author_response.errors[0].field) |> to(eq("email"))
            expect ~i(change_user_author_response.errors[0].message) |> to(eq(unquote(msg)))
          end
        end)

        it "returns success for valid author id", validation: true, valid: true do
          existing_user = build(:user)
          existing_author = build(:author)

          %{access_token: access_token} = creator()
          create_user_response = create_user(input: prepare_user(existing_user), author: prepare_author(existing_author), access_token: access_token, conn: shared.conn)

          author = build(:author)
          create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

          change_user_author_response = change_user_author(id: ~i(create_user_response.data.createUser.id), author: %{id: ~i(create_response.data.createAuthor.id)}, access_token: access_token, conn: shared.conn)

          expect ~i(change_user_author_response.errors) |> to(be_nil())
          assert check_author(~i(change_user_author_response.data.changeUserAuthor.author), ~i(create_response.data.createAuthor))
        end

        it "returns success for valid author name", validation: true, valid: true do
          existing_user = build(:user)
          existing_author = build(:author)

          %{access_token: access_token} = creator()
          create_user_response = create_user(input: prepare_user(existing_user), author: prepare_author(existing_author), access_token: access_token, conn: shared.conn)

          author = build(:author)
          create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

          change_user_author_response = change_user_author(id: ~i(create_user_response.data.createUser.id), author: %{name: author.name |> String.upcase()}, access_token: access_token, conn: shared.conn)

          expect ~i(change_user_author_response.errors) |> to(be_nil())
          assert check_author(~i(change_user_author_response.data.changeUserAuthor.author), ~i(create_response.data.createAuthor))
        end

        it "returns success for valid author email", validation: true, valid: true do
          existing_user = build(:user)
          existing_author = build(:author)

          %{access_token: access_token} = creator()
          create_user_response = create_user(input: prepare_user(existing_user), author: prepare_author(existing_author), access_token: access_token, conn: shared.conn)

          author = build(:author)
          create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

          change_user_author_response = change_user_author(id: ~i(create_user_response.data.createUser.id), author: %{email: author.email |> String.upcase()}, access_token: access_token, conn: shared.conn)

          expect ~i(change_user_author_response.errors) |> to(be_nil())
          assert check_author(~i(change_user_author_response.data.changeUserAuthor.author), ~i(create_response.data.createAuthor))
        end

        [
          en: "Cannot find author with specified id",
          ru: "Автор с указанным id не найден"
        ] |> Enum.each(fn {locale, msg} ->
          it "returns error for unknown author id (#{locale})", validation: true, valid: false, locale: locale do
            user = build(:user)
            author = build(:author)

            %{access_token: access_token} = creator()
            create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

            change_user_author_response = change_user_author(id: ~i(create_response.data.createUser.id), author: %{id: domain_uuid(:author)}, access_token: access_token, conn: shared.conn, locale: unquote(locale))

            expect ~i(change_user_author_response.errors) |> not_to(be_empty())
            expect ~i(change_user_author_response.errors[0].operation) |> to(eq("changeUserAuthor"))
            expect ~i(change_user_author_response.errors[0].entity) |> to(eq("author"))
            expect ~i(change_user_author_response.errors[0].code) |> to(eq("missing"))
            expect ~i(change_user_author_response.errors[0].field) |> to(eq("id"))
            expect ~i(change_user_author_response.errors[0].message) |> to(eq(unquote(msg)))
          end
        end)

        [
          en: "Cannot find author with specified name",
          ru: "Автор с указанным именем не найден"
        ] |> Enum.each(fn {locale, msg} ->
          it "returns error for unknown author name (#{locale})", validation: true, valid: false, locale: locale do
            user = build(:user)
            author = build(:author)

            %{access_token: access_token} = creator()
            create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

            name = slug()
            change_user_author_response = change_user_author(id: ~i(create_response.data.createUser.id), author: %{name: name}, access_token: access_token, conn: shared.conn, locale: unquote(locale))

            expect ~i(change_user_author_response.errors) |> not_to(be_empty())
            expect ~i(change_user_author_response.errors[0].operation) |> to(eq("changeUserAuthor"))
            expect ~i(change_user_author_response.errors[0].entity) |> to(eq("author"))
            expect ~i(change_user_author_response.errors[0].code) |> to(eq("missing"))
            expect ~i(change_user_author_response.errors[0].field) |> to(eq("name"))
            expect ~i(change_user_author_response.errors[0].message) |> to(eq(unquote(msg)))
          end
        end)

        [
          en: "Cannot find author with specified email",
          ru: "Автор с указанным email не найден"
        ] |> Enum.each(fn {locale, msg} ->
          it "returns error for unknown author email (#{locale})", validation: true, valid: false, locale: locale do
            user = build(:user)
            author = build(:author)

            %{access_token: access_token} = creator()
            create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

            email = email()
            change_user_author_response = change_user_author(id: ~i(create_response.data.createUser.id), author: %{email: email}, access_token: access_token, conn: shared.conn, locale: unquote(locale))

            expect ~i(change_user_author_response.errors) |> not_to(be_empty())
            expect ~i(change_user_author_response.errors[0].operation) |> to(eq("changeUserAuthor"))
            expect ~i(change_user_author_response.errors[0].entity) |> to(eq("author"))
            expect ~i(change_user_author_response.errors[0].code) |> to(eq("missing"))
            expect ~i(change_user_author_response.errors[0].field) |> to(eq("email"))
            expect ~i(change_user_author_response.errors[0].message) |> to(eq(unquote(msg)))
          end
        end)

        [
          en: "User with the same author is already exist",
          ru: "Пользователь с аналогичным автором уже существует"
        ] |> Enum.each(fn {locale, msg} ->
          it "returns error for already used author id (#{locale})", validation: true, valid: false, locale: locale do
            existing_user = build(:user)
            existing_author = build(:author)

            %{access_token: access_token} = creator()
            author_response = create_user(input: prepare_user(existing_user), author: prepare_author(existing_author), access_token: access_token, conn: shared.conn)

            user = build(:user)
            author = build(:author)
            create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

            change_user_author_response = change_user_author(id: ~i(create_response.data.createUser.id), author: %{id: ~i(author_response.data.createUser.author.id)}, access_token: access_token, conn: shared.conn, locale: unquote(locale))

            expect ~i(change_user_author_response.errors) |> not_to(be_empty())
            expect ~i(change_user_author_response.errors[0].operation) |> to(eq("changeUserAuthor"))
            expect ~i(change_user_author_response.errors[0].entity) |> to(eq("user"))
            expect ~i(change_user_author_response.errors[0].code) |> to(eq("unique"))
            expect ~i(change_user_author_response.errors[0].field) |> to(eq("author"))
            expect ~i(change_user_author_response.errors[0].message) |> to(eq(unquote(msg)))
          end

          it "returns error for already used author name (#{locale})", validation: true, valid: false, locale: locale do
            existing_user = build(:user)
            existing_author = build(:author)

            %{access_token: access_token} = creator()
            create_user(input: prepare_user(existing_user), author: prepare_author(existing_author), access_token: access_token, conn: shared.conn)

            user = build(:user)
            author = build(:author)
            create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

            change_user_author_response = change_user_author(id: ~i(create_response.data.createUser.id), author: %{name: existing_author.name |> String.upcase()}, access_token: access_token, conn: shared.conn, locale: unquote(locale))

            expect ~i(change_user_author_response.errors) |> not_to(be_empty())
            expect ~i(change_user_author_response.errors[0].operation) |> to(eq("changeUserAuthor"))
            expect ~i(change_user_author_response.errors[0].entity) |> to(eq("user"))
            expect ~i(change_user_author_response.errors[0].code) |> to(eq("unique"))
            expect ~i(change_user_author_response.errors[0].field) |> to(eq("author"))
            expect ~i(change_user_author_response.errors[0].message) |> to(eq(unquote(msg)))
          end

          it "returns error for already used author email (#{locale})", validation: true, valid: false, locale: locale do
            existing_user = build(:user)
            existing_author = build(:author)

            %{access_token: access_token} = creator()
            create_user(input: prepare_user(existing_user), author: prepare_author(existing_author), access_token: access_token, conn: shared.conn)

            user = build(:user)
            author = build(:author)
            create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

            change_user_author_response = change_user_author(id: ~i(create_response.data.createUser.id), author: %{email: existing_author.email |> String.upcase()}, access_token: access_token, conn: shared.conn, locale: unquote(locale))

            expect ~i(change_user_author_response.errors) |> not_to(be_empty())
            expect ~i(change_user_author_response.errors[0].operation) |> to(eq("changeUserAuthor"))
            expect ~i(change_user_author_response.errors[0].entity) |> to(eq("user"))
            expect ~i(change_user_author_response.errors[0].code) |> to(eq("unique"))
            expect ~i(change_user_author_response.errors[0].field) |> to(eq("author"))
            expect ~i(change_user_author_response.errors[0].message) |> to(eq(unquote(msg)))
          end
        end)

        [
          en: "Author email cannot be empty",
          ru: "Email автора не может быть пустым"
        ] |> Enum.each(fn {locale, msg} ->
          it "returns error for author without email (#{locale})", validation: true, valid: false, locale: locale do
            existing_user = build(:user)
            existing_author = build(:author)

            %{access_token: access_token} = creator()
            create_user_response = create_user(input: prepare_user(existing_user), author: prepare_author(existing_author), access_token: access_token, conn: shared.conn)

            author = build(:author)
            create_response = create_author(input: prepare_author(author) |> Map.put(:email, nil), access_token: access_token, conn: shared.conn)

            change_user_author_response = change_user_author(id: ~i(create_user_response.data.createUser.id), author: %{id: ~i(create_response.data.createAuthor.id)}, access_token: access_token, conn: shared.conn, locale: unquote(locale))

            expect ~i(change_user_author_response.errors) |> not_to(be_empty())
            expect ~i(change_user_author_response.errors[0].operation) |> to(eq("changeUserAuthor"))
            expect ~i(change_user_author_response.errors[0].entity) |> to(eq("author"))
            expect ~i(change_user_author_response.errors[0].code) |> to(eq("required"))
            expect ~i(change_user_author_response.errors[0].field) |> to(eq("email"))
            expect ~i(change_user_author_response.errors[0].message) |> to(eq(unquote(msg)))
          end
        end)

        [
          en: "Not enough permissions to change user-author binding",
          ru: "Недостаточно прав для изменения привязки пользователя к автору"
        ] |> Enum.each(fn {locale, msg} ->
          [
            user:      false,
            moderator: true,
            admin:     true
          ] |> Enum.each(fn({user_role, is_allowed}) ->
            it "#{if is_allowed, do: "allows", else: "does not allow"} #{user_role} to change his author (#{locale})", permission: true, allow: is_allowed, self: true, locale: locale do
              user = build(unquote(user_role))
              author = build(:author)

              %{access_token: access_token} = creator()
              create_user_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

              new_author = build(:author)
              create_response = create_author(input: prepare_author(new_author), access_token: access_token, conn: shared.conn)

              access_token = auth(user, author, shared.conn)
              change_user_author_response = change_user_author(id: ~i(create_user_response.data.createUser.id), author: %{id: ~i(create_response.data.createAuthor.id)}, access_token: access_token, conn: shared.conn, locale: unquote(locale))

              if unquote(is_allowed) do
                expect ~i(change_user_author_response.errors) |> to(be_nil())
              else
                expect ~i(change_user_author_response.errors) |> not_to(be_empty())
                expect ~i(change_user_author_response.errors[0].operation) |> to(eq("changeUserAuthor"))
                expect ~i(change_user_author_response.errors[0].entity) |> to(eq("user"))
                expect ~i(change_user_author_response.errors[0].code) |> to(eq("permissions"))
                expect ~i(change_user_author_response.errors[0].field) |> to(be_nil())
                expect ~i(change_user_author_response.errors[0].message) |> to(eq(unquote(msg)))
              end
            end
          end)
        end)

        [
          en: "Not enough permissions to change user-author binding with role %{role}",
          ru: "Недостаточно прав для изменения привязки пользователя к автору с ролью %{role}"
        ] |> Enum.each(fn {locale, msg} ->
          [
            user:      [user: false, moderator: true,   admin: true],
            moderator: [user: false, moderator: false,  admin: true],
            admin:     [user: false, moderator: false,  admin: false],
          ] |> Enum.each(fn({user_role, cols}) ->
              cols |> Enum.each(fn({role, is_allowed}) ->
                it "#{if is_allowed, do: "allows", else: "does not allow"} #{role} to change #{user_role} author (#{locale})", permission: true, allow: is_allowed, role: user_role, locale: locale do
                  user = build(unquote(user_role))
                  author = build(:author)

                  %{access_token: access_token} = creator()
                  create_user_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

                  new_author = build(:author)
                  create_response = create_author(input: prepare_author(new_author), access_token: access_token, conn: shared.conn)

                  %{access_token: access_token} = unquote(:"creator_#{role}")()
                  change_user_author_response = change_user_author(id: ~i(create_user_response.data.createUser.id), author: %{id: ~i(create_response.data.createAuthor.id)}, access_token: access_token, conn: shared.conn, locale: unquote(locale))

                  if unquote(is_allowed) do
                    expect ~i(change_user_author_response.errors) |> to(be_nil())
                  else
                    expect ~i(change_user_author_response.errors) |> not_to(be_empty())
                    expect ~i(change_user_author_response.errors[0].operation) |> to(eq("changeUserAuthor"))
                    expect ~i(change_user_author_response.errors[0].entity) |> to(eq("user"))
                    expect ~i(change_user_author_response.errors[0].code) |> to(eq("permissions"))
                    expect ~i(change_user_author_response.errors[0].field) |> to(eq("role"))
                    expect ~i(change_user_author_response.errors[0].message) |> to(eq(unquote(msg) |> String.replace("%{role}", role_genitive(unquote(user_role), unquote(locale)))))
                  end
                end
            end)
          end)
        end)
      end

      describe "deleteUser" do
        it "returns success for valid id", validation: true, valid: true do
          user = build(:user)
          author = build(:author)

          %{access_token: access_token} = creator()
          create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)
          delete_response = delete_user(id: ~i(create_response.data.createUser.id), access_token: access_token, conn: shared.conn)

          expect ~i(delete_response.errors) |> to(be_nil())
          expect ~i(delete_response.data.deleteUser) |> to(be_nil())
        end

        it "returns success for valid name", validation: true, valid: true do
          user = build(:user)
          author = build(:author)

          %{access_token: access_token} = creator()
          create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)
          delete_response = delete_user(name: author.name |> String.upcase(), access_token: access_token, conn: shared.conn)

          expect ~i(delete_response.errors) |> to(be_nil())
          expect ~i(delete_response.data.deleteUser) |> to(be_nil())
        end

        it "returns success for valid email", validation: true, valid: true do
          user = build(:user)
          author = build(:author)

          %{access_token: access_token} = creator()
          create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)
          delete_response = delete_user(email: author.email |> String.upcase(), access_token: access_token, conn: shared.conn)

          expect ~i(delete_response.errors) |> to(be_nil())
          expect ~i(delete_response.data.deleteUser) |> to(be_nil())
        end

        it "returns success for current user", validation: true, valid: true, self: true do
          user = build(:user)
          author = build(:author)

          %{access_token: access_token} = creator()
          create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

          access_token = auth(user, author, shared.conn)
          delete_response = delete_user(access_token: access_token, conn: shared.conn)

          expect ~i(delete_response.errors) |> to(be_nil())
          expect ~i(delete_response.data.deleteUser) |> to(be_nil())
        end

        [
          en: "Cannot find user with specified id",
          ru: "Пользователь с указанным id не найден"
        ] |> Enum.each(fn {locale, msg} ->
          it "returns error for unknown id (#{locale})", validation: true, valid: false, locale: locale do
            %{access_token: access_token} = creator()
            delete_response = delete_user(id: domain_uuid(:user), access_token: access_token, conn: shared.conn, locale: unquote(locale))

            expect ~i(delete_response.errors) |> not_to(be_empty())
            expect ~i(delete_response.errors[0].operation) |> to(eq("deleteUser"))
            expect ~i(delete_response.errors[0].entity) |> to(eq("user"))
            expect ~i(delete_response.errors[0].code) |> to(eq("missing"))
            expect ~i(delete_response.errors[0].field) |> to(eq("id"))
            expect ~i(delete_response.errors[0].message) |> to(eq(unquote(msg)))
          end
        end)

        [
          en: "Cannot find user with specified name",
          ru: "Пользователь с указанным именем не найден"
        ] |> Enum.each(fn {locale, msg} ->
          it "returns error for unknown name (#{locale})", validation: true, valid: false, locale: locale do
            author = build(:author)

            %{access_token: access_token} = creator()
            delete_response = delete_user(name: author.name, access_token: access_token, conn: shared.conn, locale: unquote(locale))

            expect ~i(delete_response.errors) |> not_to(be_empty())
            expect ~i(delete_response.errors[0].operation) |> to(eq("deleteUser"))
            expect ~i(delete_response.errors[0].entity) |> to(eq("user"))
            expect ~i(delete_response.errors[0].code) |> to(eq("missing"))
            expect ~i(delete_response.errors[0].field) |> to(eq("name"))
            expect ~i(delete_response.errors[0].message) |> to(eq(unquote(msg)))
          end
        end)

        [
          en: "Cannot find user with specified email",
          ru: "Пользователь с указанным email не найден"
        ] |> Enum.each(fn {locale, msg} ->
          it "returns error for unknown email (#{locale})", validation: true, valid: false, locale: locale do
            author = build(:author)

            %{access_token: access_token} = creator()
            delete_response = delete_user(email: author.email, access_token: access_token, conn: shared.conn, locale: unquote(locale))

            expect ~i(delete_response.errors) |> not_to(be_empty())
            expect ~i(delete_response.errors[0].operation) |> to(eq("deleteUser"))
            expect ~i(delete_response.errors[0].entity) |> to(eq("user"))
            expect ~i(delete_response.errors[0].code) |> to(eq("missing"))
            expect ~i(delete_response.errors[0].field) |> to(eq("email"))
            expect ~i(delete_response.errors[0].message) |> to(eq(unquote(msg)))
          end
        end)

        [
          en: "Not enough permissions to delete user with role user",
          ru: "Недостаточно прав для удаления пользователя с ролью пользователя"
        ] |> Enum.each(fn {locale, msg} ->
          it "returns error for anonymous user (#{locale})", validation: true, valid: false, locale: locale do
            user = build(:user)
            author = build(:author)

            create_response = create_user(input: prepare_user(user), author: prepare_author(author), conn: shared.conn)
            delete_response = delete_user(id: ~i(create_response.data.createUser.id), conn: shared.conn, locale: unquote(locale))

            expect ~i(delete_response.errors) |> not_to(be_empty())
            expect ~i(delete_response.errors[0].operation) |> to(eq("deleteUser"))
            expect ~i(delete_response.errors[0].entity) |> to(eq("user"))
            expect ~i(delete_response.errors[0].code) |> to(eq("permissions"))
            expect ~i(delete_response.errors[0].field) |> to(eq("role"))
            expect ~i(delete_response.errors[0].message) |> to(eq(unquote(msg)))
          end
        end)

        [
          en: "Cannot find user with specified id",
          ru: "Пользователь с указанным id не найден"
        ] |> Enum.each(fn {locale, msg} ->
          it "returns error for already deleted user", validation: true, valid: false do
            user = build(:user)
            author = build(:author)

            %{access_token: access_token} = creator()
            create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)
            delete_user(id: ~i(create_response.data.createUser.id), access_token: access_token, conn: shared.conn)

            delete_response = delete_user(id: ~i(create_response.data.createUser.id), conn: shared.conn, locale: unquote(locale))

            expect ~i(delete_response.errors) |> not_to(be_empty())
            expect ~i(delete_response.errors[0].operation) |> to(eq("deleteUser"))
            expect ~i(delete_response.errors[0].entity) |> to(eq("user"))
            expect ~i(delete_response.errors[0].code) |> to(eq("missing"))
            expect ~i(delete_response.errors[0].field) |> to(eq("id"))
            expect ~i(delete_response.errors[0].message) |> to(eq(unquote(msg)))
          end
        end)

        it "accepts note for revision", audit: true do
          user = build(:user)
          author = build(:author)

          %{access_token: access_token} = creator()
          create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

          note = sentence()
          delete_response = delete_user(id: ~i(create_response.data.createUser.id), input: %{note: note}, access_token: access_token, conn: shared.conn)

          expect ~i(delete_response.errors) |> to(be_nil())
        end

        [:user, :moderator, :admin]
        |> Enum.each(fn(user_role) ->
          it "allows #{user_role} to delete himself", permission: true, allow: true, self: true do
            user = build(unquote(user_role))
            author = build(:author)

            %{access_token: access_token} = creator()
            create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

            access_token = auth(user, author, shared.conn)
            delete_response = delete_user(id: ~i(create_response.data.createUser.id), input: %{with_author: false}, access_token: access_token, conn: shared.conn)

            expect ~i(delete_response.errors) |> to(be_nil())

            get_user_response = get_user(id: ~i(create_response.data.createUser.id), conn: shared.conn)
            refute ~i(get_user_response.data.user)

            get_author_response = get_author(id: ~i(create_response.data.createUser.author.id), conn: shared.conn)
            assert ~i(get_author_response.data.author)
          end
        end)

        [:user, :moderator, :admin]
        |> Enum.each(fn(user_role) ->
          it "allows #{user_role} to delete himself with author", permission: true, allow: true, self: true do
            user = build(unquote(user_role))
            author = build(:author)

            %{access_token: access_token} = creator()
            create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

            access_token = auth(user, author, shared.conn)
            delete_response = delete_user(id: ~i(create_response.data.createUser.id), access_token: access_token, conn: shared.conn)

            expect ~i(delete_response.errors) |> to(be_nil())

            get_user_response = get_user(id: ~i(create_response.data.createUser.id), conn: shared.conn)
            refute ~i(get_user_response.data.user)

            get_author_response = get_author(id: ~i(create_response.data.createUser.author.id), conn: shared.conn)
            refute ~i(get_author_response.data.author)
          end
        end)

        [
          en: "Not enough permissions to delete user with role %{role}",
          ru: "Недостаточно прав для удаления пользователя с ролью %{role}"
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
                  delete_response = delete_user(id: ~i(create_response.data.createUser.id), input: %{with_author: false}, access_token: access_token, conn: shared.conn, locale: unquote(locale))

                  if unquote(is_allowed) do
                    expect ~i(delete_response.errors) |> to(be_nil())

                    get_user_response = get_user(id: ~i(create_response.data.createUser.id), conn: shared.conn)
                    refute ~i(get_user_response.data.user)

                    get_author_response = get_author(id: ~i(create_response.data.createUser.author.id), conn: shared.conn)
                    assert ~i(get_author_response.data.author)
                  else
                    expect ~i(delete_response.errors) |> not_to(be_empty())
                    expect ~i(delete_response.errors[0].operation) |> to(eq("deleteUser"))
                    expect ~i(delete_response.errors[0].entity) |> to(eq("user"))
                    expect ~i(delete_response.errors[0].code) |> to(eq("permissions"))
                    expect ~i(delete_response.errors[0].field) |> to(eq("role"))
                    expect ~i(delete_response.errors[0].message) |> to(eq(unquote(msg) |> String.replace("%{role}", role_genitive(unquote(user_role), unquote(locale)))))
                  end
                end
              end)
          end)

          [
            user:      [user: false, moderator: true,   admin: true],
            moderator: [user: false, moderator: false,  admin: true],
            admin:     [user: false, moderator: false,  admin: false],
          ] |> Enum.each(fn({user_role, cols}) ->
              cols |> Enum.each(fn({role, is_allowed}) ->
                it "#{if is_allowed, do: "allows", else: "does not allow"} #{role} to delete #{user_role} with author (#{locale})", permission: true, allow: is_allowed, role: user_role, locale: locale do
                  user = build(unquote(user_role))
                  author = build(:author)

                  %{access_token: access_token} = creator()
                  create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

                  %{access_token: access_token} = unquote(:"creator_#{role}")()
                  delete_response = delete_user(id: ~i(create_response.data.createUser.id), access_token: access_token, conn: shared.conn, locale: unquote(locale))

                  if unquote(is_allowed) do
                    expect ~i(delete_response.errors) |> to(be_nil())

                    get_user_response = get_user(id: ~i(create_response.data.createUser.id), conn: shared.conn)
                    refute ~i(get_user_response.data.user)

                    get_author_response = get_author(id: ~i(create_response.data.createUser.author.id), conn: shared.conn)
                    refute ~i(get_author_response.data.author)
                  else
                    expect ~i(delete_response.errors) |> not_to(be_empty())
                    expect ~i(delete_response.errors[0].operation) |> to(eq("deleteUser"))
                    expect ~i(delete_response.errors[0].entity) |> to(eq("user"))
                    expect ~i(delete_response.errors[0].code) |> to(eq("permissions"))
                    expect ~i(delete_response.errors[0].field) |> to(eq("role"))
                    expect ~i(delete_response.errors[0].message) |> to(eq(unquote(msg) |> String.replace("%{role}", role_genitive(unquote(user_role), unquote(locale)))))
                  end
                end
              end)
          end)
        end)
      end
    end
  end
end
