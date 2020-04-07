defmodule ArkenstonWeb.Schema do
  use Absinthe.Schema
  use ArkenstonWeb.Schema.Types

  query do
    import_fields :user_queries
  end

  mutation do
    import_fields :session_mutations
    import_fields :user_mutations
  end

  def middleware(middleware, _field, %Absinthe.Type.Object{identifier: identifier})
  when identifier in [:query, :subscription, :mutation] do
    [Arkenston.Middleware.HandleFields | middleware]
  end

  def middleware(middleware, _field, _object) do
    middleware
  end
end
