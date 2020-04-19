alias Arkenston.Repo
alias Arkenston.Subject
alias Arkenston.Subject.User
config = Application.get_env(:arkenston, :users)

case Subject.get_user_by(name: config[:admin][:name], role: :admin) do
  nil ->
    Repo.insert!(
      %{User.create_changeset(
          %{
            name: config[:admin][:name],
            email: config[:admin][:email],
            password: config[:admin][:password],
            role: :admin,
            note: "Seed database with #{config[:admin][:name]} user"
          }
        )
      | valid?: true}
    )

  _ ->
    :ok
end
