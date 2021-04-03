defmodule Arkenston.Schema do
  use Ecto.Schema
  import Inflex

  @id_name Application.compile_env(:arkenston, [Arkenston.Repo, :primary_key, :name])
  @id_type Application.compile_env(:arkenston, [Arkenston.Repo, :primary_key, :ecto_type])

  defmacro audited_schema(shm, do: block) do
    target = __CALLER__.module

    quote do
      alias Arkenston.Subject.User

      view_name = unquote(shm)
      data_name = "#{view_name}_data"
      audit_name = "#{view_name}_audit"

      @primary_key {unquote(@id_name), unquote(@id_type),
                    autogenerate: false, read_after_writes: true}
      @foreign_key_type unquote(@id_type)

      schema view_name do
        unquote(block)
        field :version, :integer
        field :created_at, :utc_datetime
        belongs_to :created_by, User
        field :updated_at, :utc_datetime
        belongs_to :updated_by, User
        field :note, :string
        has_many :revisions, unquote(target).Revision
        field :deleted, :boolean
      end

      defmodule Revision do
        use Ecto.Schema
        alias unquote(target)
        alias Arkenston.Subject.User

        @primary_key {unquote(@id_name), unquote(@id_type),
                      autogenerate: false, read_after_writes: true}
        @foreign_key_type unquote(@id_type)

        schema audit_name do
          unquote(block)
          belongs_to String.to_atom("#{singularize(view_name)}"), unquote(target)
          belongs_to :created_by, User
          field :created_at, :utc_datetime
          field :version, :integer
          field :note, :string
          field :deleted, :boolean
        end
      end
    end
  end
end
