defmodule ArkenstonWeb.Router do
  use ArkenstonWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", ArkenstonWeb do
    pipe_through :api
  end
end
