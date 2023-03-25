defmodule ArkenstonWeb.ErrorJSON do
  def render("500.json", _assigns) do
    %{
      errors: [
        %{
          code: 500,
          field: nil,
          message: "Internal server error"
        }
      ]
    }
  end

  def render("404.json", _assigns) do
    %{
      errors: [
        %{
          code: 404,
          field: nil,
          message: "Not found"
        }
      ]
    }
  end

  # In case no render clause matches or no
  # template is found, let's render it as 400
  def template_missing(_template, assigns) do
    render("404.json", assigns)
  end
end
