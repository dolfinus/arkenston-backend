ESpec.start

ESpec.configure fn(config) ->
  config.before fn(tags) ->
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Arkenston.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Arkenston.Repo, {:shared, self()})
    end

    {:shared, tags: tags, conn: Phoenix.ConnTest.build_conn()}
  end

  config.finally fn(_shared) ->
    Ecto.Adapters.SQL.Sandbox.checkin(Arkenston.Repo, [])

    :ok
  end
end
