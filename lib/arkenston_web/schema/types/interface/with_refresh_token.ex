defmodule ArkenstonWeb.Schema.Types.Interface.WithRefreshToken do
  use Absinthe.Schema.Notation

  interface :with_refresh_token do
    field :refresh_token, non_null(:string)

    resolve_type fn
      _, _ -> nil
    end
  end
end
