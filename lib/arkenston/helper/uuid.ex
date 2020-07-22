defmodule Arkenston.Helper.UUID do
  @spec domain_uuid(domain :: binary | atom) :: String.t
  def domain_uuid(domain) when is_binary(domain) do
    random_uuid_truncated() <> domain_hash_truncated(domain)
  end

  def domain_uuid(domain) when is_atom(domain) do
    domain_uuid(Atom.to_string(domain))
  end

  @spec check_uuid(uuid :: binary, domain :: binary | atom) :: boolean
  def check_uuid(uuid, domain) when is_binary(domain) do
    uuid |> String.ends_with?(domain_hash_truncated(domain))
  end

  def check_uuid(uuid, domain) when is_atom(domain) do
    check_uuid(uuid, Atom.to_string(domain))
  end

  defp random_uuid() do
    UUID.uuid4()
  end

  defp random_uuid_truncated() do
    random_uuid() |> String.slice(0..23)
  end

  defp domain_hash(domain) when is_binary(domain) do
    :crypto.hash(:sha, domain)
    |> Base.encode16(case: :lower)
  end

  defp domain_hash_truncated(domain) when is_binary(domain) do
    domain_hash(domain) |> String.slice(0..11)
  end
end
