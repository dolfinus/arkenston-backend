defmodule Arkenston.Resolver.AuthorResolver do
  alias Arkenston.Repo
  alias Arkenston.Subject
  alias Arkenston.Subject.{User, Author}

  alias Arkenston.Helper.QueryHelper

  @type where :: QueryHelper.query_opts() | map | list[keyword]
  @type context :: %{anonumous: true} | %{current_user: User.t()}
  @type params :: %{context: context}

  @spec all(where :: where, params :: params) :: {:ok, [Author.t()]}
  def all(where, _params) do
    {:ok, Subject.list_authors(where)}
  end

  @spec one(where :: where, params :: params) :: {:ok, Author.t() | nil}
  def one(where, _params)
      when is_map(where) and map_size(where) != 0 do
    {:ok, Subject.get_author_by(where)}
  end

  def one(_args, %{context: %{current_user: current_user}} = info)
      when not is_nil(current_user) do
    current_user = current_user |> Repo.preload(:author)
    one(%{id: current_user.author.id}, info)
  end

  def one(_args, _params) do
    {:error, :invalid_request}
  end
end
