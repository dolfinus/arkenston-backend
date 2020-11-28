defmodule Arkenston.Helper.TranslationHelper do
  alias Arkenston.I18n
  alias Trans.Translator

  def nvl_field(value) do
    case value do
      nil ->
        ""

      value ->
        value
    end
  end

  defp atomize(input) when is_atom(input) do
    input
  end

  defp atomize(input) do
    input |> String.to_existing_atom()
  end

  def translate_field(object, field, locale \\ nil) do
    case translation_container(object) do
      value when map_size(value) > 0 ->
        Translator.translate(object, field, locale || I18n.locale())

      _ ->
        nil
    end
    |> nvl_field()
  end

  def get_module(%{__struct__: struct}) do
    struct
  end

  def get_module(input) do
    input
  end

  def translation_fields(module_or_struct) do
    with module when is_atom(module) <- get_module(module_or_struct),
         true <- Kernel.function_exported?(module, :__trans__, 1) do
      module.__trans__(:fields)
    else
      _ ->
        []
    end
  end

  def translation_container_name(module_or_struct) do
    with module when is_atom(module) <- get_module(module_or_struct),
         true <- Kernel.function_exported?(module, :__trans__, 1) do
      module.__trans__(:container)
    else
      _ ->
        nil
    end
  end

  def translation_container(object) do
    container =
      case translation_container_name(object) do
        container_name when not is_nil(container_name) ->
          object |> Map.get(container_name)

        _ ->
          nil
      end

    container || %{}
  end

  def translation_locales(object) do
    keys = translation_container(object) |> Map.keys() |> Enum.map(&String.to_atom/1)
    all_locales = (keys ++ I18n.locales()) |> Enum.uniq()

    all_locales
  end

  defp shrink_translation(translation) do
    translation
    |> Enum.reduce(%{}, fn {key, value}, trans ->
      key = atomize(key)
      value = nvl_field(value)

      unless byte_size(value) == 0 do
        trans |> Map.put(key, value)
      else
        trans
      end
    end)
  end

  def nvl_translations_map(input) do
    translations = translations_map(input)

    translations
    |> Enum.reduce(%{}, fn {locale, old_translation}, acc ->
      new_translation = old_translation |> shrink_translation()

      unless Enum.empty?(new_translation) do
        acc |> Map.put(locale, old_translation)
      else
        acc
      end
    end)
  end

  def shrink_translations_map(input) do
    translations = translations_map(input)

    new_translations =
      translations
      |> Enum.reduce(%{}, fn {locale, translation}, acc ->
        translation = translation |> shrink_translation()

        unless Enum.empty?(translation) do
          acc |> Map.put(locale, translation)
        else
          acc
        end
      end)

    if map_size(new_translations) == 0 do
      nil
    else
      new_translations
    end
  end

  def translations_map(input) do
    input
    |> Enum.map(fn {locale, translation} ->
      translation =
        translation
        |> Enum.map(fn {key, value} ->
          key = atomize(key)
          value = nvl_field(value)

          {key, value}
        end)
        |> Enum.into(%{})

      {locale, translation}
    end)
    |> Enum.into(%{})
  end

  def translations_from_object(object) do
    fields = translation_fields(object)
    locales = translation_locales(object)

    locales
    |> Enum.map(fn locale ->
      translation =
        fields
        |> Enum.map(fn field ->
          field = atomize(field)
          value = translate_field(object, field, locale)

          {field, value}
        end)
        |> Enum.into(%{})

      {locale, translation}
    end)
    |> Enum.into(%{})
  end

  def translations_list_from_object(object) do
    translations_to_list(nvl_translations_map(translations_from_object(object)))
  end

  def translations_to_list(input) do
    input
    |> Enum.reduce([], fn {locale, translation}, acc ->
      translation =
        translation
        |> Enum.map(fn {key, value} ->
          key = atomize(key)
          value = nvl_field(value)

          {key, value}
        end)
        |> Enum.into(%{})
        |> Map.put(:locale, locale)

      acc ++ [translation]
    end)
  end

  def translations_from_list(input) do
    input
    |> Enum.reduce(%{}, fn translation, acc ->
      {locale, translation} = translation |> Map.pop(:locale, I18n.locale())
      locale = atomize(locale)

      translation =
        translation
        |> Enum.map(fn {key, value} ->
          key = atomize(key)
          value = nvl_field(value)

          {key, value}
        end)
        |> Enum.into(%{})

      acc |> Map.put(locale, translation)
    end)
  end

  def merge_translations(input1, input2) do
    input1 =
      translations_map(
        if is_list(input1) do
          translations_from_list(input1)
        else
          input1
        end
      )

    input2 =
      translations_map(
        if is_list(input2) do
          translations_from_list(input2)
        else
          input2
        end
      )

    Map.merge(input1, input2)
  end

  defmacro __using__(_opts \\ []) do
    quote do
      alias Arkenston.Helper.TranslationHelper

      def create_translations(attrs) do
        new_translations = attrs |> Map.get(:translations) || %{}

        virtual_fields = TranslationHelper.translation_fields(__MODULE__)
        virtual_fields_changes = attrs |> Map.take(virtual_fields)

        attrs = attrs |> Map.drop(virtual_fields)

        translations =
          TranslationHelper.merge_translations(new_translations, %{
            I18n.locale() => virtual_fields_changes
          })

        attrs
        |> Map.drop(virtual_fields)
        |> Map.put(:translations, TranslationHelper.shrink_translations_map(translations))
      end

      def update_translations(changeset, attrs) do
        virtual_fields = TranslationHelper.translation_fields(__MODULE__)

        translations =
          case Map.fetch(attrs, :translations) do
            {:ok, value} ->
              new_translations = value || %{}

              virtual_fields_changes = attrs |> Map.take(virtual_fields)

              TranslationHelper.merge_translations(new_translations, %{
                I18n.locale() => virtual_fields_changes
              })

            :error ->
              old_translations = changeset.translations || %{}

              virtual_fields = TranslationHelper.translation_fields(__MODULE__)
              virtual_fields_changes = attrs |> Map.take(virtual_fields)

              TranslationHelper.merge_translations(old_translations, %{
                I18n.locale() => virtual_fields_changes
              })
          end

        attrs
        |> Map.drop(virtual_fields)
        |> Map.put(:translations, TranslationHelper.shrink_translations_map(translations))
      end
    end
  end
end
