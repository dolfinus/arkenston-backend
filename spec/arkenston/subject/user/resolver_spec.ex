defmodule Arkenston.Subject.User.ResolverSpec do
  defmacro __using__(_opts) do
    quote do
      alias Arkenston.Subject
      alias Arkenston.Subject.{User, UserResolver}
      import Arkenston.Factories.UserFactory

      describe "login/1" do
        it "returns tokens for valid email/password" do
          user = build(:user)
          {:ok, inserted_user} = user |> Subject.create_user()
          login_result = UserResolver.login(%{email: user.email, password: user.password})
          expect login_result |> to(match_pattern {:ok, %{refresh_token: refresh_token, access_token: access_token}})
        end
        it "returns tokens for valid name/password" do
          user = build(:user)
          {:ok, inserted_user} = user |> Subject.create_user()
          login_result = UserResolver.login(%{name: user.name, password: user.password})
          expect login_result |> to(match_pattern {:ok, %{refresh_token: refresh_token, access_token: access_token}})
        end

        it "does not return tokens for invalid email/password" do
          user = build(:user)
          {:ok, inserted_user} = user |> Subject.create_user()
          Subject.delete_user(inserted_user)
          login_result = UserResolver.login(%{name: user.email, password: user.password})
          expect login_result |> to(be_error_result())
        end

        it "does not return tokens for invalid name/password" do
          user = build(:user)
          {:ok, inserted_user} = user |> Subject.create_user()
          Subject.delete_user(inserted_user)
          login_result = UserResolver.login(%{name: user.name, password: user.password})
          expect login_result |> to(be_error_result())
        end
      end

      describe "exchange/1" do
        it "returns access token for valid refresh_token" do
          user = build(:user)
          {:ok, inserted_user} = user |> Subject.create_user()
          {:ok, %{refresh_token: refresh_token}} = UserResolver.login(%{email: user.email, password: user.password})
          exchange_result = UserResolver.exchange(%{refresh_token: refresh_token})
          expect exchange_result |> to(match_pattern {:ok, %{access_token: access_token}})
        end

        it "does not accept access token" do
          user = build(:user)
          {:ok, inserted_user} = user |> Subject.create_user()
          {:ok, %{access_token: access_token}} = UserResolver.login(%{email: user.email, password: user.password})
          exchange_result = UserResolver.exchange(%{refresh_token: access_token})
          expect exchange_result |> to(be_error_result())
        end

        it "does not accept malformed token" do
          user = build(:user)
          {:ok, inserted_user} = user |> Subject.create_user()
          refresh_token = user.password
          exchange_result = UserResolver.exchange(%{refresh_token: refresh_token})
          expect exchange_result |> to(be_error_result())
        end

        it "does not accept revoked token" do
          user = build(:user)
          {:ok, inserted_user} = user |> Subject.create_user()
          {:ok, %{refresh_token: refresh_token}} = UserResolver.login(%{email: user.email, password: user.password})

          UserResolver.logout(%{refresh_token: refresh_token})

          exchange_result = UserResolver.exchange(%{refresh_token: refresh_token})
          expect exchange_result |> to(be_error_result())
        end
      end

      describe "logout/1" do
        it "returns success for valid refresh_token" do
          user = build(:user)
          {:ok, inserted_user} = user |> Subject.create_user()
          {:ok, %{refresh_token: refresh_token}} = UserResolver.login(%{email: user.email, password: user.password})
          logout_result = UserResolver.logout(%{refresh_token: refresh_token})
          expect logout_result |> to(match_pattern {:ok, nil})
        end

        it "does not accept access token" do
          user = build(:user)
          {:ok, inserted_user} = user |> Subject.create_user()
          {:ok, %{access_token: access_token}} = UserResolver.login(%{email: user.email, password: user.password})
          logout_result = UserResolver.logout(%{refresh_token: access_token})
          expect logout_result |> to(be_error_result())
        end

        it "does not accept malformed token" do
          user = build(:user)
          {:ok, inserted_user} = user |> Subject.create_user()
          refresh_token = user.password
          logout_result = UserResolver.logout(%{refresh_token: refresh_token})
          expect logout_result |> to(be_error_result())
        end

        it "does not accept already revoked token" do
          user = build(:user)
          {:ok, inserted_user} = user |> Subject.create_user()
          {:ok, %{refresh_token: refresh_token}} = UserResolver.login(%{email: user.email, password: user.password})

          UserResolver.logout(%{refresh_token: refresh_token})

          logout_result = UserResolver.logout(%{refresh_token: refresh_token})
          expect logout_result |> to(be_error_result())
        end
      end

      describe "all/2" do
        it "without where clause return all users" do
          users = build_list(3, :user)
          inserted_users = users |> Enum.map(fn (user) ->
            {:ok, inserted_user} = user |> Subject.create_user()

            inserted_user
          end) |> Enum.map(&get_user/1)

          {:ok, result} = UserResolver.all()
          all_users = result |> Enum.map(&get_user/1)

          expect all_users |> to(match_list inserted_users)
        end

        it "with id returns list with specific user only" do
          users = build_list(3, :user)
          inserted_users = users |> Enum.map(fn (user) ->
            {:ok, inserted_user} = user |> Subject.create_user()

            inserted_user
          end)

          inserted_user = inserted_users |> Enum.at(0)

          {:ok, result} = UserResolver.all(%{id: inserted_user.id})
          all_users = result |> Enum.map(&get_user/1)

          inserted_user = inserted_user |> get_user()
          expect all_users |> to(have inserted_user)
        end
      end

      describe "one/2" do
        it "with id returns specific user" do
          users = build_list(3, :user)
          inserted_users = users |> Enum.map(fn (user) ->
            {:ok, inserted_user} = user |> Subject.create_user()

            inserted_user
          end)
          inserted_user = inserted_users |> Enum.at(0)

          {:ok, result} = UserResolver.one(%{id: inserted_user.id})
          one_user = result |> get_user()

          inserted_user = inserted_user |> get_user()

          expect one_user |> to(eq inserted_user)
        end

        it "without id returns current user from context" do
          users = build_list(3, :user)
          inserted_users = users |> Enum.map(fn (user) ->
            {:ok, inserted_user} = user |> Subject.create_user()

            inserted_user
          end)

          inserted_user = inserted_users |> Enum.at(0)

          {:ok, result} = UserResolver.one(%{}, %{context: %{current_user: inserted_user}})

          inserted_user = inserted_user |> get_user()
          one_user = result |> get_user()

          expect one_user |> to(eq inserted_user)
        end
      end

      describe "create/3" do
        it "returns created user" do
          user = build(:user)

          {:ok, result} = UserResolver.create(%{input: user})
          created_user = result |> get_user()

          expect check_user(created_user, user) |> to(be_true())
        end
      end
    end
  end
end
