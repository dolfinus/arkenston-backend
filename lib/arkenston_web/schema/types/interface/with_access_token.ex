defmodule ArkenstonWeb.Schema.Types.Interface.WithAccessToken do
  use Absinthe.Schema.Notation

  interface :with_access_token do
    field :access_token, non_null(:string)

    resolve_type fn
      _, _ -> nil
    end
  end
end
