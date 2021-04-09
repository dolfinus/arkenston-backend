defmodule ArkenstonWeb.Schema do
  use Absinthe.Schema
  use ArkenstonWeb.Schema.Types

  # uncomment after solving https://github.com/absinthe-graphql/absinthe/issues/1054
  # @schema_provider Absinthe.Schema.PersistentTerm

  use Absinthe.Relay.Schema,
    flavor: :modern,
    global_id_translator: ArkenstonWeb.Schema.Helpers.IDTranslator

  alias Arkenston.Repo

  query do
    import_fields :user_queries
    import_fields :author_queries
    import_fields :node_queries
  end

  mutation do
    import_fields :user_token_mutations
    import_fields :user_mutations
    import_fields :author_mutations
  end

  def dataloader do
    Dataloader.new()
    |> Dataloader.add_source(Repo, Repo.data())
  end

  def context(ctx) do
    Map.put(ctx, :loader, dataloader())
  end

  def plugins do
    [Absinthe.Middleware.Dataloader] ++ Absinthe.Plugin.defaults()
  end
end
