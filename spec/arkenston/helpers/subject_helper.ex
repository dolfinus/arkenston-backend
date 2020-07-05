defmodule SubjectHelper do
  use GraphqlHelper
  import Indifferent.Sigils

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

      new_result = case value do
        nil ->
          result
        _ ->
          result |> Map.put(attr, value)
      end

      {attr, new_result}
    end)

    user_struct |> handle_role()
  end

  def handle_user(user) do
    {_, user_struct} = Enum.map_reduce(@check_attrs, %{}, fn (attr, result) ->
      value = user |> Indifferent.Access.get(attr)

      {attr, result |> Map.put(attr, value)}
    end)

    user_struct |> handle_role()
  end

  def check_user(user1, user2) do
    handle_user(user1) == handle_user(user2)
  end

  defp handle_role(user) do
    case user do
      %{role: role} when is_atom(role) or is_binary(role) ->
        user |> Map.put(:role, String.upcase("#{role}"))
      _ ->
        user
    end
  end

  def auth(user, conn \\ build_conn()) do
    response = auth_by_email(user, conn)
    ~i(response.result.access_token)
  end

  def auth_by_email(user, conn \\ build_conn()) do
    auth_response = make_query(conn, %{
      query: login_mutation(),
      variables: %{email: user.email, password: user.password}
    })
    ~i(auth_response.data.login)
  end

  def auth_by_name(user, conn \\ build_conn()) do
    auth_response = make_query(conn, %{
      query: login_mutation(),
      variables: %{name: user.name, password: user.password}
    })
    ~i(auth_response.data.login)
  end

  def exchange(refresh_token, conn \\ build_conn()) do
    exchange_response = make_query(conn, %{
      query: exchange_mutation(),
      variables: %{refresh_token: refresh_token}
    })
    ~i(exchange_response.data.exchange)
  end

  def logout(refresh_token, conn \\ build_conn()) do
    logout_response = make_query(conn, %{
      query: logout_mutation(),
      variables: %{refresh_token: refresh_token}
    })
    ~i(logout_response.data.logout)
  end

  def get_users(args \\ %{})
  def get_users(args) when is_list(args) do
    args = args |> Enum.into(%{})

    get_users(args)
  end

  def get_users(args) when is_map(args) do
    %{conn: conn} = args
    input = args |> Map.delete([:conn, :access_token])

    get_all_response = case args do
      %{access_token: token} when not is_nil(token) ->
        make_query(conn, %{
            query: get_users_query(),
            variables: input
          },
          token
        )
      _ ->
        make_query(conn, %{
          query: get_users_query(),
          variables: input
        })
    end

    get_all_response
  end

  def get_user(args \\ %{})
  def get_user(args) when is_list(args) do
    args = args |> Enum.into(%{})

    get_user(args)
  end

  def get_user(args) when is_map(args) do
    %{conn: conn} = args
    input = args |> Map.delete([:conn, :access_token])

    get_one_response = case args do
      %{access_token: token} when not is_nil(token) ->
        make_query(conn, %{
            query: get_user_query(),
            variables: input
          },
          token
        )
      _ ->
        make_query(conn, %{
          query: get_user_query(),
          variables: input
        })
    end

    get_one_response
  end

  def create_user(args \\ %{})
  def create_user(args) when is_list(args) do
    args = args |> Enum.into(%{})

    create_user(args)
  end

  def create_user(args) when is_map(args) do
    %{conn: conn} = args
    input = args |> Map.take([:input, :id, :name, :email])

    create_response = case args do
      %{access_token: token} when not is_nil(token) ->
        make_query(conn, %{
            query: create_user_mutation(),
            variables: input
          },
          token
        )
      _ ->
        make_query(conn, %{
          query: create_user_mutation(),
          variables: input
        })
    end

    ~i(create_response.data.createUser)
  end

  def update_user(args \\ %{})
  def update_user(args) when is_list(args) do
    args = args |> Enum.into(%{})

    update_user(args)
  end

  def update_user(args) when is_map(args) do
    %{conn: conn} = args
    input = args |> Map.take([:input, :id, :name, :email])

    update_response = case args do
      %{access_token: token} when not is_nil(token) ->
        make_query(conn, %{
            query: update_user_mutation(),
            variables: input
          },
          token
        )
      _ ->
        make_query(conn, %{
          query: update_user_mutation(),
          variables: input
        })
    end

    ~i(update_response.data.updateUser)
  end

  def delete_user(args \\ %{})
  def delete_user(args) when is_list(args) do
    args = args |> Enum.into(%{})

    delete_user(args)
  end

  def delete_user(args) when is_map(args) do
    %{conn: conn} = args
    input = args |> Map.take([:input, :id, :name, :email])

    delete_response = case args do
      %{access_token: token} when not is_nil(token) ->
        make_query(conn, %{
            query: delete_user_mutation(),
            variables: input
          },
          token
        )
      _ ->
        make_query(conn, %{
          query: delete_user_mutation(),
          variables: input
        })
    end

    ~i(delete_response.data.deleteUser)
  end
end
