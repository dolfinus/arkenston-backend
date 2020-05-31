defmodule SubjectHelper do
  @check_attrs [:name, :email, :role]
  @input_attrs [:name, :email, :role, :password]

  def login_mutation() do
    """
    mutation ($name: String, $email: String, $password: String!){
      login(name: $name, email: $email, password: $password) {
        successful
        result {
          user {
            id
            name
            email
          }
          access_token
          refresh_token
        }
        messages {
          message
          code
          field
        }
      }
    }
    """
  end

  def exchange_mutation() do
    """
    mutation ($refresh_token: String!){
      exchange(refresh_token: $refresh_token) {
        successful
        result {
          user {
            id
            name
            email
          }
          access_token
        }
        messages {
          message
          code
          field
        }
      }
    }
    """
  end

  def logout_mutation() do
    """
    mutation ($refresh_token: String!){
      logout(refresh_token: $refresh_token) {
        successful
        messages {
          message
          code
          field
        }
      }
    }
    """
  end

  def get_users_query() do
    """
    query ($id: UUID4, $name: String, $email: String, $role: UserRole){
      users(id: $id, name: $name, email: $email, role: $role) {
        id
        name
        email
        role
        note
        created_at
        created_by {
          id
          name
        }
        updated_at
        updated_by {
          id
          name
        }
        version
      }
    }
    """
  end

  def get_user_query() do
    """
    query ($id: UUID4, $name: String, $email: String, $role: UserRole){
      user(id: $id, name: $name, email: $email, role: $role) {
        id
        name
        email
        role
        note
        created_at
        created_by {
          id
          name
        }
        updated_at
        updated_by {
          id
          name
        }
        version
      }
    }
    """
  end

  def create_user_mutation do
    """
    mutation ($input: CreateUserInput!){
      createUser(input: $input) {
        successful
        result {
          id
          name
          email
          role
          version
          note
          created_at
          created_by {
            id
          }
          updated_at
          updated_by {
            id
          }
        }
        messages {
          message
          code
          field
        }
      }
    }
    """
  end

  def update_user_mutation() do
    """
    mutation ($id: UUID4, $name: String, $email: String, $input: UpdateUserInput!){
      updateUser(id: $id, name: $name, email: $email, input: $input) {
        successful
        result {
          id
          name
          email
          role
          version
          note
          created_at
          created_by {
            id
          }
          updated_at
          updated_by {
            id
          }
        }
        messages {
          message
          code
          field
        }
      }
    }
    """
  end

  def delete_user_mutation() do
    """
    mutation ($id: UUID4, $name: String, $email: String, $input: DeleteUserInput){
      deleteUser(id: $id, name: $name, email: $email, input: $input) {
        successful
        messages {
          message
          code
          field
        }
      }
    }
    """
  end

  def prepare_user(user) do
    {_, user_struct} = Enum.map_reduce(@input_attrs, %{}, fn (attr, result) ->
      value = user |> Indifferent.Access.get(attr)

      {attr, result |> Map.put(attr, value)}
    end)

    %{user_struct| role: parse_role(user_struct)}
  end

  def get_user(user) do
    {_, user_struct} = Enum.map_reduce(@check_attrs, %{}, fn (attr, result) ->
      value = user |> Indifferent.Access.get(attr)

      {attr, result |> Map.put(attr, value)}
    end)

    %{user_struct| role: parse_role(user_struct)}
  end

  def check_user(user1, user2) do
    get_user(user1) == get_user(user2)
  end

  defp parse_role(user) do
    with %{role: role} <- user do
      case role do
        role when is_atom(role) or is_binary(role) ->
          String.upcase("#{role}")
      end
    end
  end
end
