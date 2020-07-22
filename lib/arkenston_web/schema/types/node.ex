defmodule ArkenstonWeb.Schema.Types.Node do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias Arkenston.Subject

  node interface do
    resolve_type fn
      %{role: _}, _ ->
        :user
      _, _ ->
        nil
    end
  end

  object :node_queries do
    node field do
      resolve fn
        %{type: :user, id: id}, _ ->
          {:ok, Subject.get_user(id)}
          _, _ ->
            :error
      end
    end
  end
end
