defmodule Arkenston.Mutator.UserTokenMutatorSpec do
  import Arkenston.Factories.MainFactory
  import SubjectHelper
  use GraphqlHelper
  use ESpec, async: false
  import Indifferent.Sigils

  context "mutator", module: :mutator, mutation: true do
    context "user token", user: true, token: true, auth: true do
      describe "login" do
        it "returns tokens for valid email-password pair", validation: true, valid: true do
          user = build(:user)
          author = build(:author)
          create_user(input: prepare_user(user), author: prepare_author(author), conn: shared.conn)

          author = author |> Map.put(:email, author.email |> String.upcase())
          login_response = auth_by_email(user, author, shared.conn)

          expect ~i(login_response.errors) |> to(be_nil())
          expect ~i(login_response.data.login.access_token) |> not_to(be_nil())
          expect ~i(login_response.data.login.refresh_token) |> not_to(be_nil())
        end

        it "returns tokens for valid name-password pair", validation: true, valid: true do
          user = build(:user)
          author = build(:author)
          create_user(input: prepare_user(user), author: prepare_author(author), conn: shared.conn)

          author = author |> Map.put(:name, author.name |> String.upcase())
          login_response = auth_by_name(user, author, shared.conn)

          expect ~i(login_response.errors) |> to(be_nil())
          expect ~i(login_response.data.login.access_token) |> not_to(be_nil())
          expect ~i(login_response.data.login.refresh_token) |> not_to(be_nil())
        end

        [
          en: "Cannot find user",
          ru: "Пользователь не найден"
        ] |> Enum.each(fn {locale, msg} ->
          it "does not return tokens for unknown email (#{locale})", validation: true, valid: false, locale: locale do
            user = build(:user)
            author = build(:author)
            login_response = auth_by_email(user, author, shared.conn, unquote(locale))

            expect ~i(login_response.errors) |> not_to(be_empty())
            expect ~i(login_response.errors[0].operation) |> to(eq("login"))
            expect ~i(login_response.errors[0].entity) |> to(eq("user"))
            expect ~i(login_response.errors[0].code) |> to(eq("missing"))
            expect ~i(login_response.errors[0].field) |> to(be_nil())
            expect ~i(login_response.errors[0].message) |> to(eq(unquote(msg)))
          end

          it "does not return tokens for unknown name (#{locale})", validation: true, valid: false, locale: locale do
            user = build(:user)
            author = build(:author)
            login_response = auth_by_name(user, author, shared.conn, unquote(locale))

            expect ~i(login_response.errors) |> not_to(be_empty())
            expect ~i(login_response.errors[0].operation) |> to(eq("login"))
            expect ~i(login_response.errors[0].entity) |> to(eq("user"))
            expect ~i(login_response.errors[0].code) |> to(eq("missing"))
            expect ~i(login_response.errors[0].field) |> to(be_nil())
            expect ~i(login_response.errors[0].message) |> to(eq(unquote(msg)))
          end
        end)

        [
          en: "Incorrect login credentials",
          ru: "Неправильные данные для входа"
        ] |> Enum.each(fn {locale, msg} ->
          it "does not return tokens for invalid email-password pair (#{locale})" , validation: true, valid: false, locale: locale do
            user = build(:user)
            author = build(:author)
            create_user(input: prepare_user(user), author: prepare_author(author), conn: shared.conn)

            user = build(:user)
            login_response = auth_by_email(user, author, shared.conn, unquote(locale))

            expect ~i(login_response.errors) |> not_to(be_empty())
            expect ~i(login_response.errors[0].operation) |> to(eq("login"))
            expect ~i(login_response.errors[0].entity) |> to(eq("user"))
            expect ~i(login_response.errors[0].code) |> to(eq("credentials"))
            expect ~i(login_response.errors[0].field) |> to(be_nil())
            expect ~i(login_response.errors[0].message) |> to(eq(unquote(msg)))
          end

          it "does not return tokens for invalid name-password pair (#{locale})", validation: true, valid: false, locale: locale do
            user = build(:user)
            author = build(:author)
            create_user(input: prepare_user(user), author: prepare_author(author), conn: shared.conn)

            user = build(:user)
            login_response = auth_by_name(user, author, shared.conn, unquote(locale))

            expect ~i(login_response.errors) |> not_to(be_empty())
            expect ~i(login_response.errors[0].operation) |> to(eq("login"))
            expect ~i(login_response.errors[0].entity) |> to(eq("user"))
            expect ~i(login_response.errors[0].code) |> to(eq("credentials"))
            expect ~i(login_response.errors[0].field) |> to(be_nil())
            expect ~i(login_response.errors[0].message) |> to(eq(unquote(msg)))
          end
        end)
      end

      describe "exchange_token" do
        it "returns access token for valid refresh_token", validation: true, valid: true do
          user = build(:user)
          author = build(:author)
          create_user(input: prepare_user(user), author: prepare_author(author), conn: shared.conn)

          login_response = auth_by_email(user, author, shared.conn)
          refresh_token = ~i(login_response.data.login.refresh_token)

          exchange_token_response = exchange_token(refresh_token, shared.conn)

          expect ~i(exchange_token_response.errors) |> to(be_nil())
          expect ~i(exchange_token_response.data.exchangeToken.access_token) |> not_to(be_nil())
        end

        [
          en: "Token type is not valid",
          ru: "Некорректный тип токена"
        ] |> Enum.each(fn {locale, msg} ->
          it "does not accept access token (#{locale})", validation: true, valid: false, locale: locale do
            user = build(:user)
            author = build(:author)
            create_user(input: prepare_user(user), author: prepare_author(author), conn: shared.conn)

            login_response = auth_by_email(user, author, shared.conn)
            access_token = ~i(login_response.data.login.access_token)

            exchange_token_response = exchange_token(access_token, shared.conn, unquote(locale))

            expect ~i(exchange_token_response.errors) |> not_to(be_empty())
            expect ~i(exchange_token_response.errors[0].operation) |> to(eq("exchangeToken"))
            expect ~i(exchange_token_response.errors[0].entity) |> to(eq("token"))
            expect ~i(exchange_token_response.errors[0].code) |> to(eq("invalidType"))
            expect ~i(exchange_token_response.errors[0].field) |> to(eq("refreshToken"))
            expect ~i(exchange_token_response.errors[0].message) |> to(eq(unquote(msg)))
          end
        end)

        [
          en: "Refresh token value %value is not valid",
          ru: "Некорректное значение %value токена обновления"
        ] |> Enum.each(fn {locale, msg} ->
          it "does not accept invalid token (#{locale})", validation: true, valid: false, locale: locale do
            user = build(:user)
            author = build(:author)
            create_user(input: prepare_user(user), author: prepare_author(author), conn: shared.conn)

            exchange_token_response = exchange_token(user.password, shared.conn, unquote(locale))

            expect ~i(exchange_token_response.errors) |> not_to(be_empty())
            expect ~i(exchange_token_response.errors[0].operation) |> to(eq("exchangeToken"))
            expect ~i(exchange_token_response.errors[0].entity) |> to(eq("token"))
            expect ~i(exchange_token_response.errors[0].code) |> to(eq("invalid"))
            expect ~i(exchange_token_response.errors[0].field) |> to(eq("refreshToken"))
            expect ~i(exchange_token_response.errors[0].message) |> to(eq(unquote(msg) |> String.replace("%value", user.password)))
          end
        end)

        [
          en: "Token has been revoked",
          ru: "Токен был отозван"
        ] |> Enum.each(fn {locale, msg} ->
          it "does not accept revoked token (#{locale})", validation: true, valid: false, locale: locale do
            user = build(:user)
            author = build(:author)
            create_user(input: prepare_user(user), author: prepare_author(author), conn: shared.conn)

            login_response = auth_by_email(user, author, shared.conn)
            refresh_token = ~i(login_response.data.login.refresh_token)

            logout(refresh_token, shared.conn)
            exchange_token_response = exchange_token(refresh_token, shared.conn, unquote(locale))

            expect ~i(exchange_token_response.errors) |> not_to(be_empty())
            expect ~i(exchange_token_response.errors[0].operation) |> to(eq("exchangeToken"))
            expect ~i(exchange_token_response.errors[0].entity) |> to(eq("token"))
            expect ~i(exchange_token_response.errors[0].code) |> to(eq("revoked"))
            expect ~i(exchange_token_response.errors[0].field) |> to(eq("refreshToken"))
            expect ~i(exchange_token_response.errors[0].message) |> to(eq(unquote(msg)))
          end
        end)
      end

      describe "logout" do
        it "returns success for valid refresh_token", validation: true, valid: true do
          user = build(:user)
          author = build(:author)
          create_user(input: prepare_user(user), author: prepare_author(author), conn: shared.conn)

          login_response = auth_by_email(user, author, shared.conn)
          refresh_token = ~i(login_response.data.login.refresh_token)

          logout_response = logout(refresh_token, shared.conn)

          expect ~i(logout_response.errors) |> to(be_nil())
          expect ~i(logout_response.data.logout) |> to(be_nil())
        end

        [
          en: "Token type is not valid",
          ru: "Некорректный тип токена"
        ] |> Enum.each(fn {locale, msg} ->
          it "does not accept access token (#{locale})", validation: true, valid: false, locale: locale do
            user = build(:user)
            author = build(:author)
            create_user(input: prepare_user(user), author: prepare_author(author), conn: shared.conn)

            login_response = auth_by_email(user, author, shared.conn)
            access_token = ~i(login_response.data.login.access_token)

            logout_response = logout(access_token, shared.conn, unquote(locale))

            expect ~i(logout_response.errors) |> not_to(be_empty())
            expect ~i(logout_response.errors[0].operation) |> to(eq("logout"))
            expect ~i(logout_response.errors[0].entity) |> to(eq("token"))
            expect ~i(logout_response.errors[0].code) |> to(eq("invalidType"))
            expect ~i(logout_response.errors[0].field) |> to(eq("refreshToken"))
            expect ~i(logout_response.errors[0].message) |> to(eq(unquote(msg)))
          end
        end)

        [
          en: "Refresh token value %value is not valid",
          ru: "Некорректное значение %value токена обновления"
        ] |> Enum.each(fn {locale, msg} ->
          it "does not accept invalid token (#{locale})", validation: true, valid: false, locale: locale do
            user = build(:user)
            author = build(:author)
            create_user(input: prepare_user(user), author: prepare_author(author), conn: shared.conn)

            logout_response = logout(user.password, shared.conn, unquote(locale))

            expect ~i(logout_response.errors) |> not_to(be_empty())
            expect ~i(logout_response.errors[0].operation) |> to(eq("logout"))
            expect ~i(logout_response.errors[0].entity) |> to(eq("token"))
            expect ~i(logout_response.errors[0].code) |> to(eq("invalid"))
            expect ~i(logout_response.errors[0].field) |> to(eq("refreshToken"))
            expect ~i(logout_response.errors[0].message) |> to(eq(unquote(msg) |> String.replace("%value", user.password)))
          end
        end)

        [
          en: "Token has been revoked",
          ru: "Токен был отозван"
        ] |> Enum.each(fn {locale, msg} ->
          it "does not accept already revoked token (#{locale})", validation: true, valid: false, locale: locale do
            user = build(:user)
            author = build(:author)
            create_user(input: prepare_user(user), author: prepare_author(author), conn: shared.conn)

            login_response = auth_by_email(user, author, shared.conn)
            refresh_token = ~i(login_response.data.login.refresh_token)

            logout(refresh_token, shared.conn)
            logout_response = logout(refresh_token, shared.conn, unquote(locale))

            expect ~i(logout_response.errors) |> not_to(be_empty())
            expect ~i(logout_response.errors[0].operation) |> to(eq("logout"))
            expect ~i(logout_response.errors[0].entity) |> to(eq("token"))
            expect ~i(logout_response.errors[0].code) |> to(eq("revoked"))
            expect ~i(logout_response.errors[0].field) |> to(eq("refreshToken"))
            expect ~i(logout_response.errors[0].message) |> to(eq(unquote(msg)))
          end
        end)
      end
    end
  end
end
