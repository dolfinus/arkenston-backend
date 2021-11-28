defmodule Arkenston.Payload.ValidationMessage do
  use Arkenston.Helper.StructHelper

  @enforce_keys [:code]
  defstruct operation: nil, entity: nil, field: nil, message: nil, code: nil, options: []

  @type operation :: String.t() | nil
  @type entity :: String.t() | nil
  @type field :: String.t() | nil
  @type message :: String.t() | nil
  @type code :: String.t() | nil
  @type options :: [Keyword.t()]

  @type t :: %__MODULE__{
          operation: operation,
          entity: entity,
          message: message,
          code: code,
          options: options
        }
end
