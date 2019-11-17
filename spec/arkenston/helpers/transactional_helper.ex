defmodule TransactionalHelper do
  defmacro transactional(name, [do: block]) do
    quote do
      it unquote(name) do
        Arkenston.Repo.transaction(fn ->
          unquote(block)
          Arkenston.Repo.rollback("End of test")
        end)
      end
    end
  end
end
