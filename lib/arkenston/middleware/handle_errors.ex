defmodule Arkenston.Middleware.HandleErrors do
  @moduledoc false

  require Indifferent

  alias Arkenston.I18n

  alias AbsintheErrorPayload.Payload
  alias Arkenston.Payload.{ErrorMessage, ValidationMessage}

  def build_payload(
        %{errors: [%Ecto.Changeset{} = error], definition: definition, context: context} =
          resolution,
        config
      ) do
    payload = convert_to_payload(error, definition, context)

    build_resolution(payload, resolution, config)
  end

  def build_payload(
        %{value: value, errors: [], definition: definition, context: context} = resolution,
        config
      ) do
    payload = convert_to_payload(value, definition, context)

    build_resolution(payload, resolution, config)
  end

  def build_payload(
        %{errors: errors, definition: definition, context: context} = resolution,
        config
      ) do
    payload = convert_to_payload({:error, errors}, definition, context)

    build_resolution(payload, resolution, config)
  end

  def build_resolution(payload, resolution, _config) do
    if payload.successful do
      %{resolution | value: payload.result, errors: []}
    else
      %{resolution | value: nil, errors: payload.messages}
    end
  end

  def convert_to_payload({:error, %ValidationMessage{} = message}, definition, context) do
    error_payload(message, definition, context)
  end

  def convert_to_payload({:error, %ErrorMessage{} = message}, definition, context) do
    error_payload(message, definition, context)
  end

  def convert_to_payload(%ValidationMessage{} = message, definition, context) do
    error_payload(message, definition, context)
  end

  def convert_to_payload(%ErrorMessage{} = message, definition, context) do
    error_payload(message, definition, context)
  end

  def convert_to_payload({:error, message}, definition, context) when is_binary(message) do
    error_payload(message, definition, context)
  end

  def convert_to_payload({:error, message}, definition, context) when is_atom(message),
    do: convert_to_payload({:error, "#{message}"}, definition, context)

  def convert_to_payload({:error, list}, definition, context) when is_list(list),
    do: error_payload(list, definition, context)

  def convert_to_payload(%Ecto.Changeset{valid?: false} = changeset, definition, context) do
    errors =
      changeset
      |> AbsintheErrorPayload.ChangesetParser.extract_messages()

    errors =
      errors
      |> Enum.map(fn error ->
        default_options = [{error.field, changeset.changes |> Map.get(error.field)}]

        options =
          error.options
          |> Enum.reduce(default_options, fn option, acc ->
            case option do
              %{key: key, value: value} ->
                acc ++ [{key, value}]

              %{} = map ->
                acc ++ Enum.into(map, [])

              _ ->
                acc
            end
          end)

        error |> Map.put(:options, options)
      end)

    convert_to_payload({:error, errors}, definition, context)
  end

  def convert_to_payload(value, _definition, _context), do: success_payload(value)

  def success_payload(result) do
    %Payload{successful: true, result: result}
  end

  def error_payload(messages, definition, context) when is_list(messages) do
    messages =
      Enum.map(messages, fn message ->
        prepare_message(message, definition, context, message.options)
      end)

    %Payload{successful: false, messages: messages}
  end

  def error_payload(message, definition, context),
    do: error_payload([message], definition, context)

  defp camelized_name(nil), do: nil

  defp camelized_name(field) do
    field
    |> to_string()
    |> Absinthe.Utils.camelize(lower: true)
  end

  defp prepare_message(
         %AbsintheErrorPayload.ValidationMessage{} = message,
         definition,
         context,
         opts
       ) do
    error_message(
      message.code,
      definition,
      context,
      message.options ++ [field: message.field] ++ opts
    )
  end

  defp prepare_message(%ValidationMessage{} = message, definition, context, opts) do
    error_message(
      message.code,
      definition,
      context,
      message.options ++ [entity: message.entity, field: message.field] ++ opts
    )
  end

  defp prepare_message(message, definition, context, opts)
       when is_binary(message) or is_atom(message) do
    error_message(message, definition, context, opts)
  end

  defp prepare_message(message, _definition, _context, _opts) do
    raise ArgumentError, "Unexpected validation message: #{inspect(message)}"
  end

  def error_message(code, definition, context, opts) do
    field = opts |> Keyword.get(:field) |> I18n.normalize_field()

    entity =
      (opts |> Keyword.get(:entity) || definition.schema_node.type)
      |> I18n.normalize_entity()

    operation =
      (opts |> Keyword.get(:operation) || definition.name)
      |> I18n.normalize_atom()

    locale =
      case context do
        %{locale: locale} -> locale
        _ -> nil
      end

    value =
      opts
      |> Keyword.get(
        field,
        get_argument(definition.arguments, field) ||
          get_argument(definition.arguments, "#{entity}.#{field}") ||
          get_argument(definition.arguments, "input.#{field}")
      )

    new_opts =
      case value do
        nil -> opts
        _ -> [{field, value}] ++ opts
      end

    new_opts =
      new_opts
      |> Keyword.put(:field, field)
      |> Keyword.put(:operation, operation)
      |> Keyword.put(:entity, entity)

    translation = translate_errors(code, locale, new_opts)

    message =
      case translation do
        {:ok, result} ->
          result

        _ ->
          code |> I18n.stringify()
      end

    %ErrorMessage{
      code: camelized_name(code),
      operation: camelized_name(operation),
      entity: camelized_name(entity),
      field: camelized_name(field),
      message: message |> I18n.capitalize()
    }
  end

  def translate_errors(code, locale, opts) do
    field = opts |> Keyword.get(:field)

    case field do
      nil ->
        I18n.translate("error.#{code}", locale, opts)

      _ ->
        case I18n.translate("error.field.#{code}", locale, opts) do
          {:ok, _} = result -> result
          _ -> I18n.translate("error.#{code}", locale, opts)
        end
    end
  end

  def get_argument(_arguments, key) when is_nil(key) do
    nil
  end

  def get_argument(arguments, key) when is_atom(key) do
    get_argument(arguments, to_string(key))
  end

  def get_argument(arguments, key) when not is_nil(key) do
    {head, tail} =
      case String.split(key, ".", trim: true) do
        [field] -> {field, nil}
        [head | tail] -> {head, tail |> Enum.join(".")}
      end

    arguments
    |> Enum.reduce(nil, fn argument, acc ->
      case argument do
        %{
          name: name,
          input_value: %{normalized: %Absinthe.Blueprint.Input.Object{fields: fields}}
        }
        when name == head ->
          case get_argument(fields, tail) do
            nil -> acc
            value -> value
          end

        %{
          name: name,
          input_value: %{data: enum, schema_node: %Absinthe.Type.Enum{values: values}}
        }
        when name == head ->
          {:enum, values |> Map.get(enum) |> Map.get(:name)}

        %{name: name, input_value: %{data: value}}
        when name == head ->
          value

        _ ->
          acc
      end
    end)
  end
end
