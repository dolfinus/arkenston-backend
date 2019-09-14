defmodule Arkenston.Schema do
  use Ecto.Schema
  import Inflex

  defmacro audited_schema(shm, [do: block]) do
    quote do
      orig_name  = unquote(shm)
      audit_name = "#{orig_name}_audit"

      schema orig_name do
        has_many :revisions, __MODULE__.Revision
        unquote(block)
        field :deleted,    :boolean
        field :updated_at, :utc_datetime
      end

      defmodule Revision do
        use Ecto.Schema
        alias __MODULE__
        alias Arkenston.Subject.User

        schema audit_name do
          belongs_to String.to_atom("#{singularize(orig_name)}"), __MODULE__, foreign_key: String.to_atom("#{singularize(orig_name)}_id")
          has_one :author, User, foreign_key: :author_id
          unquote(block)
          field :deleted,     :boolean
          field :inserted_at, :utc_datetime
        end
      end
    end
  end
end
