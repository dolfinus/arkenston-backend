defmodule ArkenstonWeb.Schema.Mutation.Author do
  use Absinthe.Schema.Notation
  import AbsintheErrorPayload.Payload

  object :author_mutations do
    field :create_author, :author_payload do
      arg :input, non_null(:create_author_input)
      resolve &Arkenston.Mutator.AuthorMutator.create/3
      middleware &build_payload/2
    end

    field :update_author, :author_payload do
      arg :id,    :uuid4
      arg :name,  :string
      arg :email, :string
      arg :input, non_null(:update_author_input)
      resolve &Arkenston.Mutator.AuthorMutator.update/3
      middleware &build_payload/2
    end

    field :delete_author, :boolean_payload do
      arg :id,    :uuid4
      arg :name,  :string
      arg :email, :string
      arg :input, :delete_author_input
      resolve &Arkenston.Mutator.AuthorMutator.delete/3
      middleware &build_payload/2
    end
  end
end
