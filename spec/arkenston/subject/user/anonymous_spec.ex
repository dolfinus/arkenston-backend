defmodule Arkenston.Subject.User.AnonymousSpec do
  defmacro __using__(_opts) do
    quote do
      alias Arkenston.Subject
      alias Arkenston.Subject.User

      @config Application.get_env(:arkenston, :users)
      @anonymous %{
                id: @config[:anonymous][:id],
                name: @config[:anonymous][:name],
                email: nil,
                password_hash: nil,
                role: :user
              }
      @anonymous_user struct(%User{}, @anonymous)

      describe "list_users/0" do
        it "returns anonymous" do
          anonymous = get_user(@anonymous_user)
          expect get_user_list() |> to(match_list [anonymous])
        end
      end

      describe "get_user!/1" do
        it "returns anonymous with with id #{@anonymous.id}" do
          anonymous = Subject.get_user(@anonymous.id)
          expect get_user(anonymous) |> to(eq get_user(@anonymous_user))
        end
      end

      describe "create_user/1" do
        it "returns error changeset" do
          expect Subject.create_user(@anonymous) |> to(match_pattern {:error, %Ecto.Changeset{}})
        end
      end

      describe "update_user/2" do
        it "returns error changeset" do
          expect Subject.update_user(@anonymous_user) |> to(match_pattern {:error, %Ecto.Changeset{}})
        end
      end

      describe "delete_user/1" do
        it "returns error" do
          expect Subject.delete_user(@anonymous_user) |> to(match_pattern {:error, %Ecto.Changeset{}})
        end
      end
    end
  end
end
