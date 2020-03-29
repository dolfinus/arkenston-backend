defmodule Arkenston.I18n do
  use Linguist.Vocabulary

  locale_files = Path.wildcard([__DIR__, "i18n", "*.{yml,yaml}"] |> Enum.join("/"))

  Enum.each(locale_files, fn(path) ->
    case Regex.run(~r/.*(\w+)\.ya?ml$/iuU, path) do
      lang when not is_nil(lang) ->
        locale(Enum.at(lang, 1), path)
    end
  end)
end
