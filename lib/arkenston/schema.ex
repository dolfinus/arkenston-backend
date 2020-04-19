defmodule Arkenston.Schema do
  use Ecto.Schema
  import Inflex

  @id_name Application.get_env(:arkenston, Arkenston.Repo)[:migration_primary_key][:name]
  @id_type Application.get_env(:arkenston, Arkenston.Repo)[:migration_primary_key][:type]

  defmacro audited_schema(shm, [do: block]) do
    target = __CALLER__.module

    quote do
      orig_name  = unquote(shm)
      audit_name = "#{orig_name}_audit"

      @primary_key {unquote(@id_name), unquote(@id_type), autogenerate: false, read_after_writes: true}
      @foreign_key_type unquote(@id_type)

      schema orig_name do
        unquote(block)
        belongs_to  :first_revision,  unquote(target).Revision
        belongs_to  :latest_revision, unquote(target).Revision
        has_many    :revisions,       unquote(target).Revision
      end

      defmodule Revision do
        use Ecto.Schema
        alias unquote(target)
        alias Arkenston.Subject.User

        @primary_key {unquote(@id_name), unquote(@id_type), autogenerate: false, read_after_writes: true}
        @foreign_key_type unquote(@id_type)

        schema audit_name do
          unquote(block)
          belongs_to String.to_atom("#{singularize(orig_name)}"), unquote(target)
          belongs_to :created_by, User
          field :created_at,     :utc_datetime
          field :version,        :integer
        end
      end
    end
  end
end
