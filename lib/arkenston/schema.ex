defmodule Arkenston.Schema do
  use Ecto.Schema
  import Inflex

  defmacro audited_schema(shm, [do: block]) do
    target = __CALLER__.module
    quote do
      orig_name  = unquote(shm)
      audit_name = "#{orig_name}_audit"

      schema orig_name do
        unquote(block)
        has_one  :first_revision,  unquote(target).Revision
        has_one  :latest_revision, unquote(target).Revision
        has_many :revisions,       unquote(target).Revision
        field    :deleted, :boolean
      end

      defmodule Revision do
        use Ecto.Schema
        alias unquote(target)
        alias Arkenston.Subject.User

        schema audit_name do
          unquote(block)
          belongs_to String.to_atom("#{singularize(orig_name)}"), unquote(target)
          belongs_to :created_by, User
          field :deleted,        :boolean
          field :created_at,     :utc_datetime
        end
      end
    end
  end
end
