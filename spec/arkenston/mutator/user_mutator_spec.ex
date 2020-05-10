defmodule Arkenston.Mutator.UserMutatorSpec do
  alias Arkenston.Subject
  alias Arkenston.Mutator.UserMutator
  import Arkenston.Factories.UserFactory
  import SubjectHelper
  use ESpec

  @valid_attrs %{name: "text", password: "not_null", email: "it@example.com", role: :user}

  context "mutator", module: :mutator, mutator: true do
    context "with user", user: true do
      describe "create/3" do
        it "returns created user" do
          user = build(:user)

          {:ok, result} = UserMutator.create(%{input: user})
          created_user = result |> get_user()

          expect check_user(created_user, user)
        end
      end

      describe "update/3" do
        it "returns updated user" do
          user = build(:user)
          {:ok, inserted_user} = user |> Subject.create_user()

          {:ok, result} = UserMutator.update(%{id: inserted_user.id, input: @valid_attrs})
          updated_user = result |> get_user()
          expected_user = user |> Map.merge(@valid_attrs)

          expect check_user(updated_user, expected_user)
        end
      end

      describe "delete/3" do
        it "returns nil for success" do
          user = build(:user)
          {:ok, inserted_user} = user |> Subject.create_user()

          {:ok, result} = UserMutator.delete(%{id: inserted_user.id})
          deleted_user = Subject.get_user_by(id: inserted_user.id, deleted: nil)

          expect result |> to(be_nil())
          expect deleted_user.deleted |> to(be_true())
        end
      end
    end
  end
end
