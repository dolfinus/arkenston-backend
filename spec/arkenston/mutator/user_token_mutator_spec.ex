defmodule Arkenston.Mutator.UserTokenMutatorSpec do
  import Arkenston.Factories.UserFactory
  import SubjectHelper
  use GraphqlHelper
  use ESpec
  import Indifferent.Sigils

  context "mutator", module: :mutator, mutator: true do
    context "user token", user: true, token: true do
      describe "login/1" do
        it "returns tokens for valid email/password" do
          user = build(:user)

          _create_response = make_query(build_conn(), %{
            query: create_user_mutation(),
            variables: %{input: prepare_user(user)}
          })

          auth_response = make_query(build_conn(), %{
            query: login_mutation(),
            variables: %{email: user.email, password: user.password}
          })

          expect ~i(auth_response.data.login.successful) |> to(be_true())
          expect ~i(auth_response.data.login.result.access_token) |> not_to(be_nil())
          expect ~i(auth_response.data.login.result.refresh_token) |> not_to(be_nil())
        end

        it "returns tokens for valid name/password" do
          user = build(:user)

          _create_response = make_query(build_conn(), %{
            query: create_user_mutation(),
            variables: %{input: prepare_user(user)}
          })

          auth_response = make_query(build_conn(), %{
            query: login_mutation(),
            variables: %{name: user.name, password: user.password}
          })

          expect ~i(auth_response.data.login.successful) |> to(be_true())
          expect ~i(auth_response.data.login.result.access_token) |> not_to(be_nil())
          expect ~i(auth_response.data.login.result.refresh_token) |> not_to(be_nil())
        end

        it "does not return tokens for invalid email/password" do
          user = build(:user)

          auth_response = make_query(build_conn(), %{
            query: login_mutation(),
            variables: %{email: user.email, password: user.password}
          })

          expect ~i(auth_response.data.login.successful) |> to(be_false())
        end

        it "does not return tokens for invalid name/password" do
          user = build(:user)

          auth_response = make_query(build_conn(), %{
            query: login_mutation(),
            variables: %{name: user.name, password: user.password}
          })

          expect ~i(auth_response.data.login.successful) |> to(be_false())
        end
      end

      describe "exchange/1" do
        it "returns access token for valid refresh_token" do
          user = build(:user)

          _create_response = make_query(build_conn(), %{
            query: create_user_mutation(),
            variables: %{input: prepare_user(user)}
          })

          auth_response = make_query(build_conn(), %{
            query: login_mutation(),
            variables: %{name: user.name, password: user.password}
          })

          refresh_token = ~i(auth_response.data.login.result.refresh_token)

          exchange_response = make_query(build_conn(), %{
            query: exchange_mutation(),
            variables: %{refresh_token: refresh_token}
          })

          expect ~i(exchange_response.data.exchange.successful) |> to(be_true())
          expect ~i(exchange_response.data.exchange.result.access_token) |> not_to(be_nil())
        end

        it "does not accept access token" do
          user = build(:user)

          _create_response = make_query(build_conn(), %{
            query: create_user_mutation(),
            variables: %{input: prepare_user(user)}
          })

          auth_response = make_query(build_conn(), %{
            query: login_mutation(),
            variables: %{name: user.name, password: user.password}
          })

          access_token = ~i(auth_response.data.login.result.access_token)

          exchange_response = make_query(build_conn(), %{
            query: exchange_mutation(),
            variables: %{refresh_token: access_token}
          })

          expect ~i(exchange_response.data.exchange.successful) |> to(be_false())
        end

        it "does not accept malformed token" do
          user = build(:user)

          _create_response = make_query(build_conn(), %{
            query: create_user_mutation(),
            variables: %{input: prepare_user(user)}
          })

          exchange_response = make_query(build_conn(), %{
            query: exchange_mutation(),
            variables: %{refresh_token: user.password}
          })

          expect ~i(exchange_response.data.exchange.successful) |> to(be_false())
        end

        it "does not accept revoked token" do
          user = build(:user)

          _create_response = make_query(build_conn(), %{
            query: create_user_mutation(),
            variables: %{input: prepare_user(user)}
          })

          auth_response = make_query(build_conn(), %{
            query: login_mutation(),
            variables: %{name: user.name, password: user.password}
          })

          refresh_token = ~i(auth_response.data.login.result.refresh_token)

          _logout_response = make_query(build_conn(), %{
            query: logout_mutation(),
            variables: %{refresh_token: refresh_token}
          })

          exchange_response = make_query(build_conn(), %{
            query: exchange_mutation(),
            variables: %{refresh_token: refresh_token}
          })

          expect ~i(exchange_response.data.exchange.successful) |> to(be_false())
        end
      end

      describe "logout/1" do
        it "returns success for valid refresh_token" do
          user = build(:user)

          _create_response = make_query(build_conn(), %{
            query: create_user_mutation(),
            variables: %{input: prepare_user(user)}
          })

          auth_response = make_query(build_conn(), %{
            query: login_mutation(),
            variables: %{name: user.name, password: user.password}
          })

          refresh_token = ~i(auth_response.data.login.result.refresh_token)

          logout_response = make_query(build_conn(), %{
            query: logout_mutation(),
            variables: %{refresh_token: refresh_token}
          })

          expect ~i(logout_response.data.logout.successful) |> to(be_true())
        end

        it "does not accept access token" do
          user = build(:user)

          _create_response = make_query(build_conn(), %{
            query: create_user_mutation(),
            variables: %{input: prepare_user(user)}
          })

          auth_response = make_query(build_conn(), %{
            query: login_mutation(),
            variables: %{name: user.name, password: user.password}
          })

          access_token = ~i(auth_response.data.login.result.access_token)

          logout_response = make_query(build_conn(), %{
            query: logout_mutation(),
            variables: %{refresh_token: access_token}
          })

          expect ~i(logout_response.data.logout.successful) |> to(be_false())
        end

        it "does not accept malformed token" do
          user = build(:user)

          _create_response = make_query(build_conn(), %{
            query: create_user_mutation(),
            variables: %{input: prepare_user(user)}
          })

          logout_response = make_query(build_conn(), %{
            query: logout_mutation(),
            variables: %{refresh_token: user.password}
          })

          expect ~i(logout_response.data.logout.successful) |> to(be_false())
        end

        it "does not accept already revoked token" do
          user = build(:user)

          _create_response = make_query(build_conn(), %{
            query: create_user_mutation(),
            variables: %{input: prepare_user(user)}
          })

          auth_response = make_query(build_conn(), %{
            query: login_mutation(),
            variables: %{name: user.name, password: user.password}
          })

          refresh_token = ~i(auth_response.data.login.result.refresh_token)

          _logout_response = make_query(build_conn(), %{
            query: logout_mutation(),
            variables: %{refresh_token: refresh_token}
          })

          logout_response = make_query(build_conn(), %{
            query: logout_mutation(),
            variables: %{refresh_token: refresh_token}
          })

          expect ~i(logout_response.data.logout.successful) |> to(be_false())
        end
      end
    end
  end
end
