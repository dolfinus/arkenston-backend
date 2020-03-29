defmodule ArkenstonWeb.Schema do
  use Absinthe.Schema

  use ArkenstonWeb.Schema.Types
  use ArkenstonWeb.Schema.Query
  use ArkenstonWeb.Schema.Mutation

  def middleware(middleware, _field, %Absinthe.Type.Object{identifier: identifier})
  when identifier in [:query, :subscription, :mutation] do
    [Arkenston.Middleware.HandleFields | middleware]
  end
  def middleware(middleware, _field, _object) do
    middleware
  end
end
