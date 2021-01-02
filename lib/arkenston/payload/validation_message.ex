defmodule Arkenston.Payload.ValidationMessage do
  use Arkenston.Helper.StructHelper

  @enforce_keys [:code]
  defstruct operation: nil, entity: nil, field: nil, message: nil, code: nil, options: []
end
