defmodule Arkenston.Subject.User.BaseSpec do
  defmacro __using__(_opts) do
    quote do
      alias Arkenston.Subject
      alias Arkenston.Subject.User
      import Arkenston.Factories.UserFactory

      describe "list_users/0" do
        it "returns all users" do
          user = build(:user)
          {:ok, inserted_user} = user |> Subject.create_user()
          inserted = get_user(inserted_user)
          expect get_user_list() |> to(have inserted)
        end

        it "does not return deleted user" do
          user = build(:user)
          {:ok, inserted_user} = user |> Subject.create_user()
          inserted = get_user(inserted_user)
          Subject.delete_user(inserted_user)
          expect get_user_list() |> not_to(have inserted)
        end
      end

      describe "get_user!/1" do
        it "returns the user with given id" do
          user = build(:user)
          {:ok, inserted_user} = user |> Subject.create_user()
          fetched_user = inserted_user.id |> Subject.get_user!()
          expect check_user(fetched_user, user)
        end

        it "does not return deleted user" do
          user = build(:user)
          {:ok, inserted_user} = user |> Subject.create_user()
          {:ok, %User{}} = inserted_user |> Subject.delete_user()
          fetched_user = inserted_user.id |> Subject.get_user()
          expect fetched_user |> to(be_nil())
        end
      end

      describe "create_user/1" do
        it "with valid data creates a user" do
          user = build(:user)
          {:ok, inserted_user} = user |> Subject.create_user()
          expect check_user(inserted_user, user)
        end

        it "with invalid data returns error changeset" do
          user = build(:user, @invalid_attrs)
          expect user |> Subject.create_user() |> to(match_pattern {:error, %Ecto.Changeset{}})
        end
      end

      describe "update_user/2" do
        it "with valid data updates a user" do
          user = build(:user)
          {:ok, inserted_user} = user |> Subject.create_user()
          {:ok, updated_user} = inserted_user |> Subject.update_user(@valid_attrs)
          expect check_user(updated_user, @valid_attrs)
        end

        it "with invalid data returns error changeset" do
          user = build(:user)
          {:ok, inserted_user} = user |> Subject.create_user()
          {:error, %Ecto.Changeset{}} = inserted_user |> Subject.update_user(@invalid_attrs)
          fetched_user = Subject.get_user(inserted_user.id)
          expect check_user(fetched_user, user)
        end
      end

      describe "delete_user/1" do
        it "updates deleted field of user" do
          user = build(:user)
          {:ok, inserted_user} = user |> Subject.create_user()
          {:ok, %User{}} = inserted_user |> Subject.delete_user()
          deleted_user = Subject.get_user_by(id: inserted_user.id, deleted: nil)
          expect deleted_user.deleted |> to(be_true())
        end
      end

      describe "change_user/1" do
        it "returns a user changeset" do
          user = build(:user)
          {:ok, inserted_user} = user |> Subject.create_user()
          expect Subject.change_user(inserted_user) |> to(match_pattern %Ecto.Changeset{})
        end
      end
    end
  end
end
