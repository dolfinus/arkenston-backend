alias Arkenston.Repo
alias Arkenston.Subject
alias Arkenston.Subject.User
config = Application.get_env(:arkenston, :users)

case Subject.get_user(config[:anonymous][:id]) do
  nil ->
    Repo.insert!(
      %{
        User.create_changeset(
          %User{},
          %{
            name: config[:anonymous][:name],
            email: nil,
            password: nil,
            role: :user
          }
        ) |> Ecto.Changeset.force_change(:id, config[:anonymous][:id])
      | valid?: true}
    )

  _ ->
    :ok
end
