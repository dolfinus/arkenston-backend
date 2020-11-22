defmodule Arkenston.Mutator.UserTokenMutatorSpec do
  import Arkenston.Factories.MainFactory
  import SubjectHelper
  use GraphqlHelper
  use ESpec, async: true
  import Indifferent.Sigils

  context "mutator", module: :mutator, mutation: true do
    context "user token", user: true, token: true, auth: true do
      describe "login" do
        it "returns tokens for valid email/password", validation: true, valid: true do
          user = build(:user)
          author = build(:author)
          create_user(input: prepare_user(user), author: prepare_author(author), conn: shared.conn)

          auth_response = auth_by_email(user, author, shared.conn)

          assert ~i(auth_response.successful)
          expect ~i(auth_response.result.access_token) |> not_to(be_nil())
          expect ~i(auth_response.result.refresh_token) |> not_to(be_nil())
        end

        it "returns tokens for valid name/password", validation: true, valid: true do
          user = build(:user)
          author = build(:author)
          create_user(input: prepare_user(user), author: prepare_author(author), conn: shared.conn)

          auth_response = auth_by_name(user, author, shared.conn)

          assert ~i(auth_response.successful)
          expect ~i(auth_response.result.access_token) |> not_to(be_nil())
          expect ~i(auth_response.result.refresh_token) |> not_to(be_nil())
        end

        it "does not return tokens for invalid email/password", validation: true, valid: false do
          user = build(:user)
          author = build(:author)
          auth_response = auth_by_email(user, author, shared.conn)

          refute ~i(auth_response.successful)
        end

        it "does not return tokens for invalid name/password", validation: true, valid: false do
          user = build(:user)
          author = build(:author)
          auth_response = auth_by_name(user, author, shared.conn)

          refute ~i(auth_response.successful)
        end
      end

      describe "exchange" do
        it "returns access token for valid refresh_token", validation: true, valid: true do
          user = build(:user)
          author = build(:author)
          create_user(input: prepare_user(user), author: prepare_author(author), conn: shared.conn)

          auth_response = auth_by_email(user, author, shared.conn)
          refresh_token = ~i(auth_response.result.refresh_token)

          exchange_response = exchange(refresh_token, shared.conn)

          assert ~i(exchange_response.successful) |> to(be_true())
          expect ~i(exchange_response.result.access_token) |> not_to(be_nil())
        end

        it "does not accept access token", validation: true, valid: false do
          user = build(:user)
          author = build(:author)
          create_user(input: prepare_user(user), author: prepare_author(author), conn: shared.conn)

          auth_response = auth_by_email(user, author, shared.conn)
          access_token = ~i(auth_response.result.access_token)

          exchange_response = exchange(access_token, shared.conn)

          refute ~i(exchange_response.successful)
        end

        it "does not accept malformed token", validation: true, valid: false do
          user = build(:user)
          author = build(:author)
          create_user(input: prepare_user(user), author: prepare_author(author), conn: shared.conn)

          exchange_response = exchange(user.password, shared.conn)

          refute ~i(exchange_response.successful)
        end

        it "does not accept revoked token", validation: true, valid: false do
          user = build(:user)
          author = build(:author)
          create_user(input: prepare_user(user), author: prepare_author(author), conn: shared.conn)

          auth_response = auth_by_email(user, author, shared.conn)
          refresh_token = ~i(auth_response.result.refresh_token)

          logout(refresh_token, shared.conn)
          exchange_response = exchange(refresh_token, shared.conn)

          refute ~i(exchange_response.successful)
        end
      end

      describe "logout" do
        it "returns success for valid refresh_token", validation: true, valid: true do
          user = build(:user)
          author = build(:author)
          create_user(input: prepare_user(user), author: prepare_author(author), conn: shared.conn)

          auth_response = auth_by_email(user, author, shared.conn)
          refresh_token = ~i(auth_response.result.refresh_token)

          logout_response = logout(refresh_token, shared.conn)

          assert ~i(logout_response.successful)
        end

        it "does not accept access token", validation: true, valid: false do
          user = build(:user)
          author = build(:author)
          create_user(input: prepare_user(user), author: prepare_author(author), conn: shared.conn)

          auth_response = auth_by_email(user, author, shared.conn)
          access_token = ~i(auth_response.result.access_token)

          logout_response = logout(access_token, shared.conn)

          refute ~i(logout_response.successful)
        end

        it "does not accept malformed token", validation: true, valid: false do
          user = build(:user)
          author = build(:author)
          create_user(input: prepare_user(user), author: prepare_author(author), conn: shared.conn)

          logout_response = logout(user.password, shared.conn)

          refute ~i(logout_response.successful)
        end

        it "does not accept already revoked token", validation: true, valid: false do
          user = build(:user)
          author = build(:author)
          create_user(input: prepare_user(user), author: prepare_author(author), conn: shared.conn)

          auth_response = auth_by_email(user, author, shared.conn)
          refresh_token = ~i(auth_response.result.refresh_token)

          logout(refresh_token, shared.conn)
          logout_response = logout(refresh_token, shared.conn)

          refute ~i(logout_response.successful)
        end
      end
    end
  end
end
