defmodule ArkenstonWeb.Schema.Mutation.User do
  use Absinthe.Schema.Notation
  import Arkenston.Middleware.HandleErrors

  alias Arkenston.Mutator.UserMutator

  object :user_mutations do
    field :create_user, :user do
      arg :input, non_null(:create_user_input)
      arg :author, non_null(:create_user_author_input)
      resolve &UserMutator.create/3
      middleware &build_payload/2
    end

    field :update_user, :user do
      arg :id, :uuid6
      arg :name, :string
      arg :email, :string
      arg :input, non_null(:update_user_input)
      resolve &UserMutator.update/3
      middleware &build_payload/2
    end

    field :change_user_author, :user do
      arg :id, :uuid6
      arg :name, :string
      arg :email, :string
      arg :author, non_null(:change_user_author_input)
      resolve &UserMutator.change_author/3
      middleware &build_payload/2
    end

    field :delete_user, :user do
      arg :id, :uuid6
      arg :name, :string
      arg :email, :string
      arg :input, :delete_user_input
      resolve &UserMutator.delete/3
      middleware &build_payload/2
    end
  end
end
