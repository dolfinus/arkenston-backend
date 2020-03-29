alias Arkenston.Repo
alias Arkenston.Subject
alias Arkenston.Subject.User
config = Application.get_env(:arkenston, :users)

case Subject.get_user_by(id: config[:anonymous][:id], role: :anonymous) do
  nil ->
    Repo.insert!(
      %{
        User.create_changeset(
          %User{},
          %{
            name: config[:anonymous][:name],
            email: nil,
            password: nil,
            role: :anonymous
          }
        ) |> Ecto.Changeset.force_change(:id, config[:anonymous][:id])
      | valid?: true}
    )

  _ ->
    :ok
end
