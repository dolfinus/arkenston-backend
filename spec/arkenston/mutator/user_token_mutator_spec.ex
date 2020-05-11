defmodule Arkenston.Mutator.UserTokenMutatorSpec do
  alias Arkenston.Subject
  alias Arkenston.Mutator.UserTokenMutator
  import Arkenston.Factories.UserFactory
  use ESpec

  context "mutator", module: :mutator, mutator: true do
    context "user token", user: true, token: true do
      describe "login/1" do
        it "returns tokens for valid email/password" do
          user = build(:user)
          {:ok, _inserted_user} = user |> Subject.create_user()
          login_result = UserTokenMutator.login(%{email: user.email, password: user.password})
          expect login_result |> to(match_pattern {:ok, %{refresh_token: _refresh_token, access_token: _access_token}})
        end

        it "returns tokens for valid name/password" do
          user = build(:user)
          {:ok, _inserted_user} = user |> Subject.create_user()
          login_result = UserTokenMutator.login(%{name: user.name, password: user.password})
          expect login_result |> to(match_pattern {:ok, %{refresh_token: _refresh_token, access_token: _access_token}})
        end

        it "does not return tokens for invalid email/password" do
          user = build(:user)
          {:ok, inserted_user} = user |> Subject.create_user()
          Subject.delete_user(inserted_user)
          login_result = UserTokenMutator.login(%{name: user.email, password: user.password})
          expect login_result |> to(be_error_result())
        end

        it "does not return tokens for invalid name/password" do
          user = build(:user)
          {:ok, inserted_user} = user |> Subject.create_user()
          Subject.delete_user(inserted_user)
          login_result = UserTokenMutator.login(%{name: user.name, password: user.password})
          expect login_result |> to(be_error_result())
        end
      end

      describe "exchange/1" do
        it "returns access token for valid refresh_token" do
          user = build(:user)
          {:ok, inserted_user} = user |> Subject.create_user()
          {:ok, %{refresh_token: refresh_token}} = UserTokenMutator.login(%{email: user.email, password: user.password})
          exchange_result = UserTokenMutator.exchange(%{refresh_token: refresh_token})
          expect exchange_result |> to(match_pattern {:ok, %{access_token: _access_token}})
        end

        it "does not accept access token" do
          user = build(:user)
          {:ok, _inserted_user} = user |> Subject.create_user()
          {:ok, %{access_token: access_token}} = UserTokenMutator.login(%{email: user.email, password: user.password})
          exchange_result = UserTokenMutator.exchange(%{refresh_token: access_token})
          expect exchange_result |> to(be_error_result())
        end

        it "does not accept malformed token" do
          user = build(:user)
          {:ok, _inserted_user} = user |> Subject.create_user()
          refresh_token = user.password
          exchange_result = UserTokenMutator.exchange(%{refresh_token: refresh_token})
          expect exchange_result |> to(be_error_result())
        end

        it "does not accept revoked token" do
          user = build(:user)
          {:ok, _inserted_user} = user |> Subject.create_user()
          {:ok, %{refresh_token: refresh_token}} = UserTokenMutator.login(%{email: user.email, password: user.password})

          UserTokenMutator.logout(%{refresh_token: refresh_token})

          exchange_result = UserTokenMutator.exchange(%{refresh_token: refresh_token})
          expect exchange_result |> to(be_error_result())
        end
      end

      describe "logout/1" do
        it "returns success for valid refresh_token" do
          user = build(:user)
          {:ok, _inserted_user} = user |> Subject.create_user()
          {:ok, %{refresh_token: refresh_token}} = UserTokenMutator.login(%{email: user.email, password: user.password})
          logout_result = UserTokenMutator.logout(%{refresh_token: refresh_token})
          expect logout_result |> to(match_pattern {:ok, nil})
        end

        it "does not accept access token" do
          user = build(:user)
          {:ok, _inserted_user} = user |> Subject.create_user()
          {:ok, %{access_token: access_token}} = UserTokenMutator.login(%{email: user.email, password: user.password})
          logout_result = UserTokenMutator.logout(%{refresh_token: access_token})
          expect logout_result |> to(be_error_result())
        end

        it "does not accept malformed token" do
          user = build(:user)
          {:ok, _inserted_user} = user |> Subject.create_user()
          refresh_token = user.password
          logout_result = UserTokenMutator.logout(%{refresh_token: refresh_token})
          expect logout_result |> to(be_error_result())
        end

        it "does not accept already revoked token" do
          user = build(:user)
          {:ok, _inserted_user} = user |> Subject.create_user()
          {:ok, %{refresh_token: refresh_token}} = UserTokenMutator.login(%{email: user.email, password: user.password})

          UserTokenMutator.logout(%{refresh_token: refresh_token})

          logout_result = UserTokenMutator.logout(%{refresh_token: refresh_token})
          expect logout_result |> to(be_error_result())
        end
      end
    end
  end
end
