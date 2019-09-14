alias Arkenston.Repo
alias Arkenston.Subject
alias Arkenston.Subject.User
config = Application.get_env(:arkenston, :users)

case Subject.get_user(config[:admin][:id]) do
  nil ->
    Repo.insert!(
      %{
        User.create_changeset(
          %User{},
          %{
            name: config[:admin][:name],
            email: config[:admin][:email],
            password: config[:admin][:password],
            role: :admin
          }
        ) |> Ecto.Changeset.force_change(:id, config[:admin][:id])
      | valid?: true}
    )

  _ ->
    :ok
end
