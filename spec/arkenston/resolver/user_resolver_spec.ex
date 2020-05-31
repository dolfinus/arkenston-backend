defmodule Arkenston.Resolver.UserResolverSpec do
  import Arkenston.Factories.UserFactory
  import SubjectHelper
  use GraphqlHelper
  use ESpec
  import Indifferent.Sigils

  context "resolver", module: :resolver, resolver: true do
    context "user", user: true do
      describe "all/2" do
        it "without where clause return all users" do
          users = build_list(3, :user)
          inserted_users = users |> Enum.map(fn (user) ->
            create_response = make_query(build_conn(), %{
              query: create_user_mutation(),
              variables: %{input: prepare_user(user)}
            })

            ~i(create_response.data.createUser.result)
          end) |> Enum.map(&get_user/1)

          get_all_response = make_query(build_conn(), %{
            query: get_users_query(),
            variables: %{}
          })

          all_users = ~i(get_all_response.data.users) |> Enum.map(&get_user/1)

          expect all_users |> to(match_list inserted_users)
        end

        it "with id returns list with specific user only" do
          users = build_list(3, :user)
          inserted_users = users |> Enum.map(fn (user) ->
            create_response = make_query(build_conn(), %{
              query: create_user_mutation(),
              variables: %{input: prepare_user(user)}
            })

            ~i(create_response.data.createUser.result)
          end)

          inserted_user_id = ~i(inserted_users[0].id)
          inserted_user = ~i(inserted_users[0]) |> get_user()

          get_all_response = make_query(build_conn(), %{
            query: get_users_query(),
            variables: %{id: inserted_user_id}
          })

          all_users = ~i(get_all_response.data.users) |> Enum.map(&get_user/1)

          expect all_users |> to(have inserted_user)
        end

        it "does not return deleted user" do
          users = build_list(3, :user)
          inserted_users = users |> Enum.map(fn (user) ->
            create_response = make_query(build_conn(), %{
              query: create_user_mutation(),
              variables: %{input: prepare_user(user)}
            })

            ~i(create_response.data.createUser.result)
          end)

          inserted_user_id = ~i(inserted_users[0].id)
          inserted_user = ~i(inserted_users[0]) |> get_user()

          _delete_response = make_query(build_conn(), %{
            query: delete_user_mutation(),
            variables: %{id: inserted_user_id}
          })

          get_all_response = make_query(build_conn(), %{
            query: get_users_query(),
            variables: %{}
          })

          all_users = ~i(get_all_response.data.users) |> Enum.map(&get_user/1)

          expect all_users |> not_to(have inserted_user)
        end
      end

      describe "one/2" do
        it "with id returns specific user" do
          users = build_list(3, :user)
          inserted_users = users |> Enum.map(fn (user) ->
            create_response = make_query(build_conn(), %{
              query: create_user_mutation(),
              variables: %{input: prepare_user(user)}
            })

            ~i(create_response.data.createUser.result)
          end)

          inserted_user_id = ~i(inserted_users[0].id)
          inserted_user = ~i(inserted_users[0]) |> get_user()

          get_one_response = make_query(build_conn(), %{
            query: get_user_query(),
            variables: %{id: inserted_user_id}
          })

          one_user = ~i(get_one_response.data.user) |> get_user()

          expect one_user |> to(eq inserted_user)
        end

        it "without id returns current user from context" do
          users = build_list(3, :user)
          inserted_users = users |> Enum.map(fn (user) ->
            create_response = make_query(build_conn(), %{
              query: create_user_mutation(),
              variables: %{input: prepare_user(user)}
            })

            ~i(create_response.data.createUser.result)
          end)

          user = ~i(users[0])
          inserted_user = ~i(inserted_users[0]) |> get_user()

          auth_response = make_query(build_conn(), %{
            query: login_mutation(),
            variables: %{email: user.email, password: user.password}
          })

          access_token = ~i(auth_response.data.login.result.access_token)

          get_one_response = make_query(build_conn(), %{
              query: get_user_query(),
              variables: %{}
            },
            access_token
          )
          one_user = ~i(get_one_response.data.user) |> get_user()

          expect one_user |> to(eq inserted_user)
        end

        it "without id and context returns error" do
          get_one_response = make_query(build_conn(), %{
            query: get_user_query(),
            variables: %{}
          })

          expect ~i(get_one_response.errors) |> not_to(be_nil())
        end

        it "does not return deleted user" do
          users = build_list(3, :user)
          inserted_users = users |> Enum.map(fn (user) ->
            create_response = make_query(build_conn(), %{
              query: create_user_mutation(),
              variables: %{input: prepare_user(user)}
            })

            ~i(create_response.data.createUser.result)
          end)

          inserted_user_id = ~i(inserted_users[0].id)

          _delete_response = make_query(build_conn(), %{
            query: delete_user_mutation(),
            variables: %{id: inserted_user_id}
          })

          get_one_response = make_query(build_conn(), %{
            query: get_user_query(),
            variables: %{id: inserted_user_id}
          })

          one_user = ~i(get_one_response.data.user)

          expect one_user |> to(be_nil())
        end
      end
    end
  end
end
