alias Arkenston.Repo
alias Arkenston.I18n
alias Arkenston.Subject
alias Arkenston.Subject.Author
config = Application.get_env(:arkenston, :authors)

action = case Subject.get_author_by(name: config[:admin][:name]) do
  nil ->
    :insert
  author ->
    case author.translations do
      nil ->
        {:update, author}
      data when map_size(data) == 0 ->
        {:update, author}
      _ ->
        :skip
    end
end

case action do
  :skip ->
    :ok
  :insert ->
    Repo.insert!(
      %{Author.create_changeset(
          %{
            name: config[:admin][:name],
            email: config[:admin][:email],
            translations: I18n.locales |> Enum.map(fn locale ->
              {
                locale,
                %{
                  first_name: I18n.t!(locale |> to_string(), "default.authors.admin.first_name"),
                  middle_name: I18n.t!(locale |> to_string(), "default.authors.admin.middle_name"),
                  last_name: I18n.t!(locale |> to_string(), "default.authors.admin.last_name"),
                }
              }
            end) |> Enum.into(%{}),
            note: "Seed database with #{config[:admin][:name]} author"
          }
        )
      | valid?: true}
    )
  {:update, author} ->
    Repo.update!(
      %{Author.update_changeset(
        author,
          %{
            translations: I18n.locales |> Enum.map(fn locale ->
              {
                locale,
                %{
                  first_name: I18n.t!(locale |> to_string(), "default.authors.admin.first_name"),
                  middle_name: I18n.t!(locale |> to_string(), "default.authors.admin.middle_name"),
                  last_name: I18n.t!(locale |> to_string(), "default.authors.admin.last_name"),
                }
              }
            end) |> Enum.into(%{}),
            note: "Update #{config[:admin][:name]} author translations"
          }
        )
      | valid?: true}
    )
end
