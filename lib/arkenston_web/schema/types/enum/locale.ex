defmodule ArkenstonWeb.Schema.Types.Enum.Locale do
  use Absinthe.Schema.Notation

  enum :locale do
    values Arkenston.I18n.all_locales() |> Enum.map(&String.to_existing_atom/1)
  end
end
