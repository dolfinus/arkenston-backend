defmodule Arkenston.Payload.ErrorMessage do
  use Arkenston.Helper.StructHelper

  @enforce_keys [:code, :message]
  defstruct operation: nil, entity: nil, field: nil, message: nil, code: nil
end
