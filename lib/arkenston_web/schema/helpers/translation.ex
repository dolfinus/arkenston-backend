defmodule ArkenstonWeb.Schema.Helpers.Translation do
  alias Arkenston.I18n
  alias Arkenston.Helper.TranslationHelper

  defmacro __using__(_opts) do
    current = __MODULE__

    quote do
      use ArkenstonWeb.Schema.Helpers.Revision
      import unquote(current)
    end
  end

  defmacro translated(field, args \\ []) do
    quote do
      field unquote(field), non_null(:string), unquote_splicing(args) do
        arg :locale, :locale, default_value: nil

        resolve fn parent, args, %{context: context} ->
          locale = args |> Map.get(:locale, I18n.get_default_locale(context))
          {:ok, TranslationHelper.translate_field(parent, unquote(field), locale)}
        end
      end
    end
  end

  defmacro audited_translated(object, do: block, else: translation, after: after_block) do
    translation_type = :"#{object}_translation"
    translation_input_type = :"#{object}_translation_input"

    quote do
      object unquote(translation_type) do
        field :locale, non_null(:locale)
        unquote(translation)
      end

      input_object unquote(translation_input_type) do
        field :locale, non_null(:locale)
        unquote(translation)
      end

      audited unquote(object) do
        unquote(block)
        unquote(translation)

        field :translations, non_null(list_of(non_null(unquote(translation_type)))) do
          resolve fn parent, _args, _context ->
            translations = TranslationHelper.translations_list_from_object(parent)

            {:ok, translations}
          end
        end

        unquote(after_block)
      end
    end
  end
end
