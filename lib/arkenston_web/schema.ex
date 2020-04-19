defmodule ArkenstonWeb.Schema do
  use Absinthe.Schema
  alias Arkenston.Repo
  use ArkenstonWeb.Schema.Types

  query do
    import_fields :user_queries
  end

  mutation do
    import_fields :user_token_mutations
    import_fields :user_mutations
  end

  def dataloader(ctx) do
    Dataloader.new
    |> Dataloader.add_source(Repo, Repo.data(ctx))
  end

  def context(ctx) do
    Map.put(ctx, :loader, dataloader(ctx))
  end

  def plugins do
    [Absinthe.Middleware.Dataloader] ++ Absinthe.Plugin.defaults()
  end

  def middleware(middleware, _field, %Absinthe.Type.Object{identifier: identifier})
  when identifier in [:query, :subscription, :mutation] do
    [Arkenston.Middleware.HandleFields | middleware]
  end

  def middleware(middleware, _field, _object) do
    middleware
  end
end
