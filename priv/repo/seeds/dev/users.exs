alias Arkenston.Repo
alias Arkenston.Subject
alias Arkenston.Subject.User
authors_config = Application.get_env(:arkenston, :authors)
users_config = Application.get_env(:arkenston, :users)

author = Subject.get_author_by(name: authors_config[:admin][:name])

case Subject.get_user_by(author_id: author.id, role: :admin) do
  nil ->
    Repo.insert!(%{
      User.create_changeset(%{
        password: users_config[:admin][:password],
        role: :admin,
        author_id: author.id,
        note: "Seed database with #{authors_config[:admin][:name]} user"
      })
      | valid?: true
    })

  _ ->
    :ok
end
