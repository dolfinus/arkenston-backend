defmodule Arkenston.I18n do
  use Memoize
  alias Linguist.MemorizedVocabulary

  @default_locale Application.get_env(:arkenston, Arkenston.I18n)[:default_locale]

  locale_files = Path.wildcard([__DIR__, "i18n", "*.{yml,yaml}"] |> Enum.join("/"))

  Enum.each(locale_files, fn path ->
    case Regex.run(~r/.*(\w+)\.ya?ml$/iuU, path) do
      lang when not is_nil(lang) ->
        @external_resource path
        MemorizedVocabulary.locale(Enum.at(lang, 1) |> String.to_atom(), path)
    end
  end)

  defdelegate t(locale, path), to: MemorizedVocabulary
  defdelegate t!(locale, path), to: MemorizedVocabulary
  defdelegate t(locale, path, bindings), to: MemorizedVocabulary
  defdelegate t!(locale, path, bindings), to: MemorizedVocabulary
  defdelegate locales(), to: MemorizedVocabulary

  def default_locale() do
    @default_locale |> to_string()
  end

  def get_default_locale(%{locale: locale}) when not is_nil(locale), do: locale

  def get_default_locale(_), do: default_locale()

  @cases [:nominative, :genitive, :dative, :instrumental, :infinitive]

  def translate(path, locale \\ nil, bindings \\ []) do
    locale = locale || default_locale()

    case bindings do
      [] ->
        Memoize.Cache.get_or_run({__MODULE__, :translate, [path, locale]}, fn ->
          do_translate(path, locale, [])
        end)

      _ ->
        do_translate(path, locale, bindings)
    end
  end

  defp do_translate(path, locale, bindings) do
    bindings = handle_bindings(bindings, locale)

    options = [
      t(locale, path, bindings)
    ]

    options =
      case path do
        "field." <> rest ->
          options ++ [t(locale, "entity.#{rest}", bindings)]

        _ ->
          options
      end

    path = clear_case(path)

    options =
      options ++
        [
          t(locale, path, bindings),
          t(locale, make_case(path, :nominative), bindings),
          t(locale, make_case(path, :infinitive), bindings)
        ]

    result = {:error, :no_translation}

    options
    |> Enum.reduce(result, fn option, acc ->
      case option do
        {:ok, value} ->
          case acc do
            {:error, _} ->
              {:ok, value |> String.replace(~r/\s+/, " ")}

            _ ->
              acc
          end

        _ ->
          acc
      end
    end)
  end

  defp handle_bindings(bindings, locale) do
    old_field = bindings |> Keyword.get(:field)

    new_bindings =
      bindings
      |> Enum.reduce([], fn bind, result ->
        case bind do
          {key, value} ->
            case value do
              nil ->
                result |> Keyword.put(key, value)

              _ ->
                translated = stringify_value(key, value, locale, nil, bindings)
                result = result |> Keyword.put(key, translated)

                @cases
                |> Enum.reduce(result, fn kase, acc ->
                  translated = stringify_value(key, value, locale, kase, bindings)
                  acc |> Keyword.put(:"#{key}.#{kase}", translated)
                end)
            end
        end
      end)

    case old_field do
      nil ->
        new_bindings

      field ->
        new_value = new_bindings |> Keyword.get(field)
        new_bindings = new_bindings |> Keyword.put(:value, new_value)

        @cases
        |> Enum.reduce(new_bindings, fn kase, acc ->
          case acc |> Keyword.get(:"#{field}.#{kase}") do
            nil -> acc |> Keyword.put(:"value.#{kase}", new_value)
            kased_value -> acc |> Keyword.put(:"value.#{kase}", kased_value)
          end
        end)
    end
  end

  def normalize_value(:entity, value), do: value |> normalize_entity()
  def normalize_value(:field, value), do: value |> normalize_field()
  def normalize_value(:operation, value), do: value |> normalize_atom()
  def normalize_value(_, value), do: value

  def stringify_value(key, value, locale \\ nil, kase \\ nil, opts \\ []) do
    opts =
      opts
      |> Enum.map(fn {opt_key, opt_value} ->
        {opt_key, normalize_value(opt_key, opt_value)}
      end)

    value = normalize_value(key, value)

    field = opts |> Keyword.get(:field)

    case key do
      nil ->
        ""

      :entity ->
        value
        |> stringify_entity(locale, kase)

      :field ->
        value
        |> stringify_field(opts |> Keyword.get(:entity), locale, kase)

      :operation ->
        value
        |> stringify_operation(locale, kase, opts |> Keyword.get(:entity_kase))

      ^field ->
        case value do
          {:enum, enum} ->
            enum = enum |> to_string() |> String.downcase()
            code = "#{field}.#{enum}"

            case code |> stringify_field(opts |> Keyword.get(:entity), locale, kase) do
              ^code ->
                enum
                |> to_string()

              result ->
                result
            end

          _ ->
            value
            |> to_string()
        end

      _ ->
        value
        |> to_string()
    end
  end

  def stringify(item) do
    item
    |> to_string()
    |> String.replace("_", " ")
  end

  defmemo clear_case(code) do
    @cases
    |> Enum.reduce(code, fn other_kase, acc ->
      acc |> String.replace_suffix(".#{other_kase}", "")
    end)
  end

  defmemo make_case(code, kase \\ nil) do
    kase =
      case kase do
        nil -> ""
        "" -> ""
        "." <> _rest = value -> value
        other -> ".#{other}"
      end

    code <> kase
  end

  def stringify_entity(code, locale \\ nil, kase \\ nil) do
    case translate(make_case("entity.#{code}", kase), locale) do
      {:ok, translated} -> translated
      _ -> stringify(code)
    end
  end

  def stringify_field(code, entity, locale \\ nil, kase \\ nil) do
    new_value =
      case entity do
        nil ->
          translate(make_case("field.#{code}", kase), locale)

        _ ->
          case translate(make_case("field.#{entity}.#{code}", kase), locale, entity: entity) do
            {:ok, translated} -> {:ok, translated}
            _ -> translate(make_case("field.#{code}", kase), locale, entity: entity)
          end
      end

    case new_value do
      {:ok, translated} -> translated
      _ -> stringify(code)
    end
  end

  def stringify_operation(code, locale \\ nil, kase \\ nil, entity_kase \\ nil) do
    entity_kase = entity_kase || :genitive

    case translate(make_case("operation.#{code}", kase), locale) do
      {:ok, result} ->
        result

      _ ->
        case String.split("#{code}", "_") do
          [action] ->
            action

          [head | tail] ->
            tail = tail |> Enum.join("_")

            op =
              case translate(make_case("operation.#{head}", kase), locale) do
                {:ok, op} -> op
                _ -> head
              end

            entity =
              case translate(make_case("entity.#{tail}", entity_kase), locale) do
                {:ok, entity} -> entity
                _ -> tail |> String.replace("_", " ")
              end

            op <> " " <> entity
        end
    end
  end

  def normalize_atom(atom) do
    case atom do
      nil ->
        nil

      _ ->
        atom
        |> to_string()
        |> Macro.underscore()
        |> String.replace("/", ".")
        |> String.to_existing_atom()
    end
  end

  def replace_field(field) do
    case field do
      :password_hash -> :password
      _ -> field
    end
  end

  def normalize_field(field) do
    case field do
      {:enum, enum} ->
        new_enum =
          enum
          |> to_string()
          |> String.downcase()
          |> normalize_atom()

        {:enum, new_enum}

      _ ->
        field
        |> normalize_atom()
        |> replace_field()
    end
  end

  def replace_entity(entity) do
    case entity do
      :user_token -> :user
      :user_access_token -> :token
      :user_logout -> :token
      _ -> entity
    end
  end

  def normalize_entity(entity) do
    entity
    |> normalize_atom()
    |> replace_entity()
  end

  def capitalize(string) do
    case string |> String.first() do
      nil ->
        ""

      head ->
        tail = string |> String.replace_prefix(head, "")

        String.upcase(head) <> tail
    end
  end

  def extract_accept_language(conn) do
    case Plug.Conn.get_req_header(conn, "accept-language") do
      [value | _] ->
        value
        |> String.split(",")
        |> Enum.map(&parse_language_option/1)
        |> Enum.sort(&(&1.quality > &2.quality))
        |> Enum.map(& &1.tag)
        |> Enum.reject(&is_nil/1)
        |> ensure_language_fallbacks()

      _ ->
        []
    end
  end

  defp parse_language_option(string) do
    captures = Regex.named_captures(~r/^\s?(?<tag>[\w\-]+)(?:;q=(?<quality>[\d\.]+))?$/i, string)

    quality =
      case Float.parse(captures["quality"] || "1.0") do
        {val, _} -> val
        _ -> 1.0
      end

    %{tag: captures["tag"], quality: quality}
  end

  defp ensure_language_fallbacks(tags) do
    Enum.flat_map(tags, fn tag ->
      [language | _] = String.split(tag, "-")
      if Enum.member?(tags, language), do: [tag], else: [tag, language]
    end)
  end
end
