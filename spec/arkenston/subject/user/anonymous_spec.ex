defmodule Arkenston.Subject.User.AnonymousSpec do
  defmacro __using__(_opts) do
    quote do
      alias Arkenston.Subject
      alias Arkenston.Subject.User

      @config Application.get_env(:arkenston, :users)
      @anonymous %{
                id: @config[:anonymous][:id],
                name: @config[:anonymous][:name],
                email: @config[:anonymous][:email],
                password_hash: nil,
                role: :anonymous
              }
      @anonymous_user struct(%User{}, @anonymous)

      describe "list_users/0" do
        it "does not return anonymous" do
          anonymous = get_user(@anonymous_user)
          expect get_user_list() |> not_to(match_list [anonymous])
        end
      end

      describe "get_user_by!/1" do
        it "returns anonymous with role #{@anonymous.role}" do
          anonymous = Subject.get_user_by!(role: @anonymous.role)
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
