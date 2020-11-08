defmodule ArkenstonWeb.ErrorView do
  use ArkenstonWeb, :view

  def render("404.json", _assigns) do
    %{
      id: "NOT FOUND",
      status: 404
    }
  end

  # In case no render clause matches or no
  # template is found, let's render it as 400
  def template_not_found(_template, assigns) do
    render "404.json", assigns
  end
end
