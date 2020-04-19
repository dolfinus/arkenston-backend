defmodule Arkenston.Mutator.UserMutatorSpec do
  alias Arkenston.Mutator.UserMutator
  import Arkenston.Factories.UserFactory
  import SubjectHelper
  use ESpec

  context "mutator", module: :mutator, mutator: true do
    context "with user", user: true do
      describe "create/3" do
        it "returns created user" do
          user = build(:user)

          {:ok, result} = UserMutator.create(%{input: user})
          created_user = result |> get_user()

          expect check_user(created_user, user) |> to(be_true())
        end
      end
    end
  end
end
