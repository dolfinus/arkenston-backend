defmodule Arkenston.Mutator.UserMutatorSpec do
  import Arkenston.Factories.UserFactory
  import SubjectHelper
  use GraphqlHelper
  import Faker.Lorem, only: [sentence: 0]
  use ESpec
  import Indifferent.Sigils

  @valid_attrs %{name: "text", password: "not_null", email: "it@example.com", role: :user}

  context "mutator", module: :mutator, mutator: true do
    context "user", user: true do
      describe "create/3" do
        it "returns created user for valid attrs" do
          valid_user = build(:user)

          create_response = make_query(build_conn(), %{
            query: create_user_mutation(),
            variables: %{input: prepare_user(valid_user)}
          })

          expect ~i(create_response.data.createUser.successful) |> to(be_true())
          expect check_user(~i(create_response.data.createUser.result), valid_user) |> to(be_true())
        end

        it "returns error for invalid attrs" do
          existing_user = build(:user)

          _create_response = make_query(build_conn(), %{
            query: create_user_mutation(),
            variables: %{input: prepare_user(existing_user)}
          })

          invalid_user = build(:user, name: existing_user.name, email: existing_user.email)

          create_response = make_query(build_conn(), %{
            query: create_user_mutation(),
            variables: %{input: prepare_user(invalid_user)}
          })
          expect ~i(create_response.data.createUser.successful) |> to(be_false())
        end

        it "accepts note for revision" do
          note = sentence()
          valid_user_with_note = build(:user)

          create_response = make_query(build_conn(), %{
            query: create_user_mutation(),
            variables: %{input: prepare_user(valid_user_with_note) |> Map.merge(%{note: note})}
          })

          expect ~i(create_response.data.createUser.result.note) |> to(eq(note))
        end

        it "sets revision version to 1" do
          valid_user = build(:user)

          create_response = make_query(build_conn(), %{
            query: create_user_mutation(),
            variables: %{input: prepare_user(valid_user)}
          })

          expect ~i(create_response.data.createUser.result.version) |> to(eq(1))
        end

        it "sets created_by to non-nil if context is not empty" do
          valid_creator = build(:user)
          valid_user    = build(:user)

          creator_response = make_query(build_conn(), %{
            query: create_user_mutation(),
            variables: %{input: prepare_user(valid_creator)}
          })

          creator_id = ~i(creator_response.data.createUser.result.id)

          auth_response = make_query(build_conn(), %{
            query: login_mutation(),
            variables: %{email: valid_creator.email, password: valid_creator.password}
          })

          access_token = ~i(auth_response.data.login.result.access_token)

          create_response = make_query(build_conn(), %{
              query: create_user_mutation(),
              variables: %{input: prepare_user(valid_user)}
            },
            access_token
          )

          expect ~i(create_response.data.createUser.result.created_by.id) |> to(eq(creator_id))
        end

        it "sets created_by to nil if context is empty" do
          valid_user = build(:user)

          create_response = make_query(build_conn(), %{
            query: create_user_mutation(),
            variables: %{input: prepare_user(valid_user)}
          })

          expect ~i(create_response.data.createUser.result.created_by) |> to(be_nil())
        end

        it "sets created_at" do
          valid_user = build(:user)

          create_response = make_query(build_conn(), %{
            query: create_user_mutation(),
            variables: %{input: prepare_user(valid_user)}
          })

          expect ~i(create_response.data.createUser.result.created_at) |> not_to(be_nil())
        end

        it "does not set updated_at" do
          valid_user = build(:user)

          create_response = make_query(build_conn(), %{
            query: create_user_mutation(),
            variables: %{input: prepare_user(valid_user)}
          })

          expect ~i(create_response.data.createUser.result.updated_at) |> to(be_nil())
        end
      end

      describe "update/3" do
        it "returns success for valid id" do
          user = build(:user)

          create_response = make_query(build_conn(), %{
            query: create_user_mutation(),
            variables: %{input: prepare_user(user)}
          })

          user_id = ~i(create_response.data.createUser.result.id)

          update_response = make_query(build_conn(), %{
            query: update_user_mutation(),
            variables: %{id: user_id, input: prepare_user(@valid_attrs)}
          })

          expect ~i(update_response.data.updateUser.successful) |> to(be_true())

          expected_user = user |> Map.merge(@valid_attrs)
          expect check_user(~i(update_response.data.updateUser.result), expected_user) |> to(be_true())
        end

        it "returns error for unknown id" do
          update_response = make_query(build_conn(), %{
            query: update_user_mutation(),
            variables: %{id: Ecto.UUID.generate(), input: prepare_user(@valid_attrs)}
          })

          expect ~i(update_response.data.updateUser.successful) |> to(be_false())
        end

        it "returns success for valid name" do
          user = build(:user)

          _create_response = make_query(build_conn(), %{
            query: create_user_mutation(),
            variables: %{input: prepare_user(user)}
          })

          update_response = make_query(build_conn(), %{
            query: update_user_mutation(),
            variables: %{name: user.name, input: prepare_user(@valid_attrs)}
          })

          expect ~i(update_response.data.updateUser.successful) |> to(be_true())

          expected_user = user |> Map.merge(@valid_attrs)
          expect check_user(~i(update_response.data.updateUser.result), expected_user) |> to(be_true())
        end

        it "returns error for unknown name" do
          user = build(:user)
          update_response = make_query(build_conn(), %{
            query: update_user_mutation(),
            variables: %{name: user.name, input: prepare_user(@valid_attrs)}
          })

          expect ~i(update_response.data.updateUser.successful) |> to(be_false())
        end

        it "returns success for valid email" do
          user = build(:user)

          _create_response = make_query(build_conn(), %{
            query: create_user_mutation(),
            variables: %{input: prepare_user(user)}
          })

          update_response = make_query(build_conn(), %{
            query: update_user_mutation(),
            variables: %{email: user.email, input: prepare_user(@valid_attrs)}
          })

          expect ~i(update_response.data.updateUser.successful) |> to(be_true())

          expected_user = user |> Map.merge(@valid_attrs)
          expect check_user(~i(update_response.data.updateUser.result), expected_user) |> to(be_true())
        end

        it "returns error for unknown email" do
          user = build(:user)
          update_response = make_query(build_conn(), %{
            query: update_user_mutation(),
            variables: %{email: user.email, input: prepare_user(@valid_attrs)}
          })

          expect ~i(update_response.data.updateUser.successful) |> to(be_false())
        end

        it "returns success for current user" do
          user = build(:user)

          _create_response = make_query(build_conn(), %{
            query: create_user_mutation(),
            variables: %{input: prepare_user(user)}
          })

          auth_response = make_query(build_conn(), %{
            query: login_mutation(),
            variables: %{email: user.email, password: user.password}
          })

          access_token = ~i(auth_response.data.login.result.access_token)

          update_response = make_query(build_conn(), %{
              query: update_user_mutation(),
              variables: %{input: prepare_user(@valid_attrs)}
            },
            access_token
          )

          expect ~i(update_response.data.updateUser.successful) |> to(be_true())

          expected_user = user |> Map.merge(@valid_attrs)
          expect check_user(~i(update_response.data.updateUser.result), expected_user) |> to(be_true())
        end

        it "returns error for invalid attrs" do
          existing_user = build(:user)

          _create_response = make_query(build_conn(), %{
            query: create_user_mutation(),
            variables: %{input: prepare_user(existing_user)}
          })

          user = build(:user)

          create_response = make_query(build_conn(), %{
            query: create_user_mutation(),
            variables: %{input: prepare_user(user)}
          })

          user_id = ~i(create_response.data.createUser.result.id)

          update_response = make_query(build_conn(), %{
            query: update_user_mutation(),
            variables: %{id: user_id, input: %{name: existing_user.name, email: existing_user.email}}
          })

          expect ~i(update_response.data.updateUser.successful) |> to(be_false())
        end

        it "returns error for anonymous user" do
          update_response = make_query(build_conn(), %{
            query: update_user_mutation(),
            variables: %{input: prepare_user(@valid_attrs)}
          })

          expect ~i(update_response.data.updateUser.successful) |> to(be_false())
        end

        it "returns error for already deleted user" do
          user = build(:user)

          create_response = make_query(build_conn(), %{
            query: create_user_mutation(),
            variables: %{input: prepare_user(user)}
          })

          user_id = ~i(create_response.data.result.id)

          _delete_response = make_query(build_conn(), %{
            query: delete_user_mutation(),
            variables: %{id: user_id}
          })

          update_response = make_query(build_conn(), %{
            query: update_user_mutation(),
            variables: %{id: user_id, input: prepare_user(@valid_attrs)}
          })

          expect ~i(update_response.data.updateUser.successful) |> to(be_false())
        end

        it "accepts note for revision" do
          user = build(:user)

          create_response = make_query(build_conn(), %{
            query: create_user_mutation(),
            variables: %{input: prepare_user(user)}
          })

          user_id = ~i(create_response.data.createUser.result.id)

          note = sentence()
          update_response = make_query(build_conn(), %{
            query: update_user_mutation(),
            variables: %{id: user_id, input: %{note: note}}
          })

          expect ~i(update_response.data.updateUser.result.note) |> to(eq(note))
        end

        it "increments revision version" do
          user = build(:user)

          create_response = make_query(build_conn(), %{
            query: create_user_mutation(),
            variables: %{input: prepare_user(user)}
          })

          user_id = ~i(create_response.data.createUser.result.id)
          initial_version = ~i(create_response.data.createUser.result.version)

          update_response = make_query(build_conn(), %{
            query: update_user_mutation(),
            variables: %{id: user_id, input: prepare_user(@valid_attrs)}
          })

          expect ~i(update_response.data.updateUser.result.version) |> to(be(:>, initial_version))
        end

        it "sets updated_by to non-nil if context is not empty" do
          valid_creator = build(:user)
          valid_user    = build(:user)

          updator_response = make_query(build_conn(), %{
            query: create_user_mutation(),
            variables: %{input: prepare_user(valid_creator)}
          })

          updator_id = ~i(updator_response.data.createUser.result.id)

          auth_response = make_query(build_conn(), %{
            query: login_mutation(),
            variables: %{email: valid_creator.email, password: valid_creator.password}
          })

          access_token = ~i(auth_response.data.login.result.access_token)

          create_response = make_query(build_conn(), %{
            query: create_user_mutation(),
            variables: %{input: prepare_user(valid_user)}
          })

          user_id = ~i(create_response.data.createUser.result.id)

          update_response = make_query(build_conn(), %{
              query: update_user_mutation(),
              variables: %{id: user_id, input: prepare_user(@valid_attrs)}
            },
            access_token
          )

          expect ~i(update_response.data.updateUser.result.updated_by.id) |> to(eq(updator_id))
        end

        it "sets updated_by to nil if context is empty" do
          user = build(:user)

          create_response = make_query(build_conn(), %{
            query: create_user_mutation(),
            variables: %{input: prepare_user(user)}
          })

          user_id = ~i(create_response.data.createUser.result.id)

          update_response = make_query(build_conn(), %{
            query: update_user_mutation(),
            variables: %{id: user_id, input: prepare_user(@valid_attrs)}
          })

          expect ~i(update_response.data.updateUser.result.updated_by) |> to(be_nil())
        end

        it "does not touch created_at" do
          user = build(:user)

          create_response = make_query(build_conn(), %{
            query: create_user_mutation(),
            variables: %{input: prepare_user(user)}
          })

          user_id = ~i(create_response.data.createUser.result.id)
          created_at = ~i(create_response.data.createUser.result.created_at)

          update_response = make_query(build_conn(), %{
            query: update_user_mutation(),
            variables: %{id: user_id, input: prepare_user(@valid_attrs)}
          })

          expect ~i(update_response.data.updateUser.result.created_at) |> to(eq(created_at))
        end

        it "touches updated_at" do
          user = build(:user)

          create_response = make_query(build_conn(), %{
            query: create_user_mutation(),
            variables: %{input: prepare_user(user)}
          })

          user_id = ~i(create_response.data.createUser.result.id)
          expect ~i(create_response.data.createUser.result.updated_at) |> to(be_nil())

          update_response = make_query(build_conn(), %{
            query: update_user_mutation(),
            variables: %{id: user_id, input: prepare_user(@valid_attrs)}
          })

          expect ~i(update_response.data.updateUser.result.updated_at) |> not_to(be_nil())
        end
      end

      describe "delete/3" do
        it "returns success for valid id" do
          user = build(:user)

          create_response = make_query(build_conn(), %{
              query: create_user_mutation(),
              variables: %{input: prepare_user(user)}
            })

          user_id = ~i(create_response.data.createUser.result.id)

          delete_response = make_query(build_conn(), %{
            query: delete_user_mutation(),
            variables: %{id: user_id}
          })

          expect ~i(delete_response.data.deleteUser.successful) |> to(be_true())
          expect ~i(delete_response.data.deleteUser.result) |> to(be_nil())
        end

        it "returns error for unknown id" do
          delete_response = make_query(build_conn(), %{
            query: delete_user_mutation(),
            variables: %{id: Ecto.UUID.generate()}
          })

          expect ~i(delete_response.data.deleteUser.successful) |> to(be_false())
        end

        it "returns success for valid name" do
          user = build(:user)

          _create_response = make_query(build_conn(), %{
            query: create_user_mutation(),
            variables: %{input: prepare_user(user)}
          })

          delete_response = make_query(build_conn(), %{
            query: delete_user_mutation(),
            variables: %{name: user.name}
          })

          expect ~i(delete_response.data.deleteUser.successful) |> to(be_true())
          expect ~i(delete_response.data.deleteUser.result) |> to(be_nil())
        end

        it "returns error for unknown name" do
          user = build(:user)
          delete_response = make_query(build_conn(), %{
            query: delete_user_mutation(),
            variables: %{name: user.name}
          })

          expect ~i(delete_response.data.deleteUser.successful) |> to(be_false())
        end

        it "returns success for valid email" do
          user = build(:user)

          _create_response = make_query(build_conn(), %{
            query: create_user_mutation(),
            variables: %{input: prepare_user(user)}
          })

          delete_response = make_query(build_conn(), %{
            query: delete_user_mutation(),
            variables: %{email: user.email}
          })

          expect ~i(delete_response.data.deleteUser.successful) |> to(be_true())
          expect ~i(delete_response.data.deleteUser.result) |> to(be_nil())
        end

        it "returns error for unknown email" do
          user = build(:user)
          delete_response = make_query(build_conn(), %{
            query: delete_user_mutation(),
            variables: %{email: user.email}
          })

          expect ~i(delete_response.data.deleteUser.successful) |> to(be_false())
        end

        it "returns success for current user" do
          user = build(:user)

          _create_response = make_query(build_conn(), %{
            query: create_user_mutation(),
            variables: %{input: prepare_user(user)}
          })

          auth_response = make_query(build_conn(), %{
            query: login_mutation(),
            variables: %{email: user.email, password: user.password}
          })

          access_token = ~i(auth_response.data.login.result.access_token)

          delete_response = make_query(build_conn(), %{
              query: delete_user_mutation(),
              variables: %{}
            },
            access_token
          )

          expect ~i(delete_response.data.deleteUser.successful) |> to(be_true())
          expect ~i(delete_response.data.deleteUser.result) |> to(be_nil())
        end

        it "returns error for already deleted user" do
          user = build(:user)

          create_response = make_query(build_conn(), %{
            query: create_user_mutation(),
            variables: %{input: prepare_user(user)}
          })

          user_id = ~i(create_response.data.result.id)

          _delete_response = make_query(build_conn(), %{
            query: delete_user_mutation(),
            variables: %{id: user_id}
          })

          delete_response = make_query(build_conn(), %{
            query: delete_user_mutation(),
            variables: %{id: user_id}
          })

          expect ~i(delete_response.data.deleteUser.successful) |> to(be_false())
        end

        it "accepts note for revision" do
          user = build(:user)

          create_response = make_query(build_conn(), %{
            query: create_user_mutation(),
            variables: %{input: prepare_user(user)}
          })

          user_id = ~i(create_response.data.createUser.result.id)

          note = sentence()
          delete_response = make_query(build_conn(), %{
            query: delete_user_mutation(),
            variables: %{id: user_id, input: %{note: note}}
          })

          expect ~i(delete_response.data.deleteUser.successful) |> to(be_true())
        end
      end
    end
  end
end
