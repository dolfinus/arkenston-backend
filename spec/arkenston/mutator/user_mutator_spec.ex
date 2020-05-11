defmodule Arkenston.Mutator.UserMutatorSpec do
  alias Arkenston.Subject
  alias Arkenston.Mutator.UserMutator
  import Arkenston.Factories.UserFactory
  import SubjectHelper
  import Faker.Lorem, only: [sentence: 0]
  use ESpec

  @valid_attrs %{name: "text", password: "not_null", email: "it@example.com", role: :user}
  @invalid_attrs %{name: nil, password: nil, email: nil, role: nil}

  context "mutator", module: :mutator, mutator: true do
    context "user", user: true do
      describe "create/3" do
        it "returns created user" do
          valid_user = build(:user)

          {:ok, result} = UserMutator.create(%{input: valid_user})
          created_user = result |> get_user()

          expect check_user(created_user, valid_user)
        end

        it "returns invalid changeset for invalid attrs" do
          invalid_user = build(:user) |> Map.merge(@invalid_attrs)
          {:ok, changeset} = UserMutator.create(%{input: invalid_user})
          expect changeset.valid? |> to(be_false())
        end
      end

      describe "update/3" do
        it "returns updated user for valid attrs" do
          user = build(:user)
          {:ok, inserted_user} = user |> Subject.create_user()

          result = UserMutator.update(%{id: inserted_user.id, input: @valid_attrs})
          expect result |> to(be_ok_result())

          {:ok, result_} = result
          updated_user   = result_ |> get_user()
          expected_user  = user |> Map.merge(@valid_attrs)
          expect check_user(updated_user, expected_user)
        end

        it "returns invalid changeset for invalid attrs" do
          user = build(:user)
          {:ok, inserted_user} = user |> Subject.create_user()

          {:ok, changeset} = UserMutator.update(%{id: inserted_user.id, input: @invalid_attrs})
          expect changeset.valid? |> to(be_false())
        end

        it "returns error for unknown id" do
          result = UserMutator.update(%{id: Ecto.UUID.generate(), input: @valid_attrs})
          expect result |> to(be_error_result())
        end

        it "returns error for unknown name" do
          user = build(:user)
          result = UserMutator.update(%{name: user.name, input: @valid_attrs})
          expect result |> to(be_error_result())
        end

        it "returns error for unknown email" do
          user = build(:user)
          result = UserMutator.update(%{email: user.email, input: @valid_attrs})
          expect result |> to(be_error_result())
        end

        it "returns error for already deleted user" do
          user = build(:user)
          {:ok, inserted_user} = user |> Subject.create_user()
          result = UserMutator.delete(%{id: inserted_user.id})
          expect result |> to(be_ok_result())

          result = UserMutator.update(%{id: inserted_user.id, input: @valid_attrs})
          expect result |> to(be_error_result())
        end
      end

      describe "delete/3" do
        it "returns nil for success" do
          user = build(:user)
          {:ok, inserted_user} = user |> Subject.create_user()

          result = UserMutator.delete(%{id: inserted_user.id})
          expect result |> to(be_ok_result())

          deleted_user = Subject.get_user_by(id: inserted_user.id, deleted: nil)
          expect deleted_user.deleted |> to(be_true())
        end

        it "returns invalid changeset for invalid attrs" do
          user = build(:user)
          {:ok, inserted_user} = user |> Subject.create_user()

          {:ok, changeset} = UserMutator.delete(%{id: inserted_user.id, input: @invalid_attrs})
          expect changeset.valid? |> to(be_false())
        end

        it "returns error for unknown id" do
          result = UserMutator.delete(%{id: Ecto.UUID.generate()})
          expect result |> to(be_error_result())
        end

        it "returns error for unknown name" do
          user = build(:user)
          result = UserMutator.delete(%{name: user.name})
          expect result |> to(be_error_result())
        end

        it "returns error for unknown email" do
          user = build(:user)
          result = UserMutator.delete(%{email: user.email})
          expect result |> to(be_error_result())
        end

        it "returns error for already deleted user" do
          user = build(:user)
          {:ok, inserted_user} = user |> Subject.create_user()
          result = UserMutator.delete(%{id: inserted_user.id})
          expect result |> to(be_ok_result())

          result = UserMutator.delete(%{id: inserted_user.id})
          expect result |> to(be_error_result())
        end
      end
    end
  end
end
