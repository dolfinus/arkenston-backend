defmodule Arkenston.I18n do
  use Linguist.Vocabulary

  locale_files = Path.wildcard([__DIR__, "i18n", "*.{yml,yaml}"] |> Enum.join("/"))

  Enum.each(locale_files, fn(path) ->
    lang = Regex.run(~r/.*(\w+)\.ya?ml$/i, path)
    if lang != nil do
      locale Enum.at(lang, 1), path
    end
  end)
end
