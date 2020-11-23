defmodule SubjectHelper do
  use GraphqlHelper
  import Indifferent.Sigils

  @author_check_attrs [:name, :email]
  @author_input_attrs [:id, :name, :email, :first_name, :last_name, :middle_name, :translations]

  @user_check_attrs [:role, author: @author_check_attrs]
  @user_input_attrs [:role, :password]

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

  def get_authors_query() do
    """
    query ($id: UUID4, $name: String, $email: String, $deleted: Boolean, $first: PageSize, $last: PageSize, $after: String, $before: String){
      authors(id: $id, name: $name, email: $email, deleted: $deleted, first: $first, last: $last, after: $after, before: $before) {
        pageInfo {
          hasNextPage
          hasPreviousPage
          startCursor
          endCursor
        }
        edges {
          cursor
          node {
            id
            name
            email
            first_name
            last_name
            middle_name
            translations {
              locale
              first_name
              last_name
              middle_name
            }
            note
            created_at
            created_by {
              id
            }
            updated_at
            updated_by {
              id
            }
            version
          }
        }
      }
    }
    """
  end

  def get_users_query() do
    """
    query ($id: UUID4, $name: String, $email: String, $role: UserRole, $deleted: Boolean, $first: PageSize, $last: PageSize, $after: String, $before: String){
      users(id: $id, name: $name, email: $email, role: $role, deleted: $deleted, first: $first, last: $last, after: $after, before: $before) {
        pageInfo {
          hasNextPage
          hasPreviousPage
          startCursor
          endCursor
        }
        edges {
          cursor
          node {
            id
            author(deleted: $deleted) {
              id
              name
              email
            }
            role
            note
            created_at
            created_by {
              id
            }
            updated_at
            updated_by {
              id
            }
            version
          }
        }
      }
    }
    """
  end

  def get_author_query() do
    """
    query ($id: UUID4, $name: String, $email: String, $deleted: Boolean){
      author(id: $id, name: $name, email: $email, deleted: $deleted) {
        id
        name
        email
        first_name
        last_name
        middle_name
        translations {
          locale
          first_name
          last_name
          middle_name
        }
        note
        created_at
        created_by {
          id
        }
        updated_at
        updated_by {
          id
        }
        version
      }
    }
    """
  end

  def get_user_query() do
    """
    query ($id: UUID4, $name: String, $email: String, $role: UserRole, $deleted: Boolean){
      user(id: $id, name: $name, email: $email, role: $role, deleted: $deleted) {
        id
        author(deleted: $deleted) {
          id
          name
          email
        }
        role
        note
        created_at
        created_by {
          id
        }
        updated_at
        updated_by {
          id
        }
        version
      }
    }
    """
  end

  def create_author_mutation do
    """
    mutation ($input: CreateAuthorInput!){
      createAuthor(input: $input) {
        successful
        result {
          id
          name
          email
          first_name
          last_name
          middle_name
          translations {
            locale
            first_name
            last_name
            middle_name
          }
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

  def create_user_mutation do
    """
    mutation ($input: CreateUserInput!, $author: CreateUserAuthorInput!){
      createUser(input: $input, author: $author) {
        successful
        result {
          id
          name
          email
          role
          version
          note
          author {
            id
            name
            email
          }
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

  def update_author_mutation() do
    """
    mutation ($id: UUID4, $name: String, $email: String, $input: UpdateAuthorInput!){
      updateAuthor(id: $id, name: $name, email: $email, input: $input) {
        successful
        result {
          id
          name
          email
          first_name
          last_name
          middle_name
          translations {
            locale
            first_name
            last_name
            middle_name
          }
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
          author {
            id
            name
            email
          }
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

  def change_user_author_mutation() do
    """
    mutation ($id: UUID4, $name: String, $email: String, $author: ChangeUserAuthorInput!){
      changeUserAuthor(id: $id, name: $name, email: $email, author: $author) {
        successful
        result {
          id
          name
          email
          role
          version
          note
          author {
            id
            name
            email
          }
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

  def delete_author_mutation() do
    """
    mutation ($id: UUID4, $name: String, $email: String, $input: DeleteAuthorInput){
      deleteAuthor(id: $id, name: $name, email: $email, input: $input) {
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

  def filter_struct(structure, template) do
    case structure do
      nil ->
        nil
      _ ->
        structure |> Enum.reduce(%{}, fn {attr, value}, acc ->
          attr = if is_atom(attr) do
            attr
          else
            attr |> String.to_atom()
          end

          cond do
            template |> Keyword.has_key?(attr) ->
              schema = template |> Keyword.get(attr)

              case schema do
                nested when is_list(nested) ->
                  acc |> Map.put(attr, value |> filter_struct(nested))

                _ ->
                  acc |> Map.put(attr, value)
              end
            template |> Enum.member?(attr) ->
              acc |> Map.put(attr, value)
            true ->
              acc
          end
        end)
    end
  end

  def prepare_author(author) do
    author |> filter_struct(@author_input_attrs)
  end

  def prepare_user(user) do
    user
    |> filter_struct(@user_input_attrs)
    |> handle_role()
  end

  def handle_author(author) do
    author |> filter_struct(@author_check_attrs)
  end

  def handle_user(user) do
    user
    |> filter_struct(@user_check_attrs)
    |> handle_role()
  end

  def check_author(author1, author2) do
    handle_author(author1) == handle_author(author2)
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

  def auth(user, author, conn \\ build_conn()) do
    response = auth_by_email(user, author, conn)
    ~i(response.result.access_token)
  end

  def auth_by_email(user, author, conn \\ build_conn()) do
    auth_response = make_query(conn, %{
      query: login_mutation(),
      variables: %{email: author.email, password: user.password}
    })

    ~i(auth_response.data.login)
  end

  def auth_by_name(user, author, conn \\ build_conn()) do
    auth_response = make_query(conn, %{
      query: login_mutation(),
      variables: %{name: author.name, password: user.password}
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

  def get_authors(args \\ %{})
  def get_authors(args) when is_list(args) do
    args = args |> Enum.into(%{})

    get_authors(args)
  end

  def get_authors(args) when is_map(args) do
    %{conn: conn} = args
    input = args |> Map.delete([:conn, :access_token])

    get_all_response = case args do
      %{access_token: token} when not is_nil(token) ->
        make_query(conn, %{
            query: get_authors_query(),
            variables: input
          },
          token
        )
      _ ->
        make_query(conn, %{
          query: get_authors_query(),
          variables: input
        })
    end

    get_all_response
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

  def get_author(args \\ %{})
  def get_author(args) when is_list(args) do
    args = args |> Enum.into(%{})

    get_author(args)
  end

  def get_author(args) when is_map(args) do
    %{conn: conn} = args
    input = args |> Map.delete([:conn, :access_token])

    get_one_response = case args do
      %{access_token: token} when not is_nil(token) ->
        make_query(conn, %{
            query: get_author_query(),
            variables: input
          },
          token
        )
      _ ->
        make_query(conn, %{
          query: get_author_query(),
          variables: input
        })
    end

    get_one_response
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

  def create_author(args \\ %{})
  def create_author(args) when is_list(args) do
    args = args |> Enum.into(%{})

    create_author(args)
  end

  def create_author(args) when is_map(args) do
    %{conn: conn} = args
    input = args |> Map.delete([:conn, :access_token])

    create_response = case args do
      %{access_token: token} when not is_nil(token) ->
        make_query(conn, %{
            query: create_author_mutation(),
            variables: input
          },
          token
        )
      _ ->
        make_query(conn, %{
          query: create_author_mutation(),
          variables: input
        })
    end

    ~i(create_response.data.createAuthor)
  end

  def create_user(args \\ %{})
  def create_user(args) when is_list(args) do
    args = args |> Enum.into(%{})

    create_user(args)
  end

  def create_user(args) when is_map(args) do
    %{conn: conn} = args
    input = args |> Map.delete([:conn, :access_token])

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

  def update_author(args \\ %{})
  def update_author(args) when is_list(args) do
    args = args |> Enum.into(%{})

    update_author(args)
  end

  def update_author(args) when is_map(args) do
    %{conn: conn} = args
    input = args |> Map.delete([:conn, :access_token])

    update_response = case args do
      %{access_token: token} when not is_nil(token) ->
        make_query(conn, %{
            query: update_author_mutation(),
            variables: input
          },
          token
        )
      _ ->
        make_query(conn, %{
          query: update_author_mutation(),
          variables: input
        })
    end

    ~i(update_response.data.updateAuthor)
  end

  def update_user(args \\ %{})
  def update_user(args) when is_list(args) do
    args = args |> Enum.into(%{})

    update_user(args)
  end

  def update_user(args) when is_map(args) do
    %{conn: conn} = args
    input = args |> Map.delete([:conn, :access_token])

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

  def change_user_author(args \\ %{})
  def change_user_author(args) when is_list(args) do
    args = args |> Enum.into(%{})

    change_user_author(args)
  end

  def change_user_author(args) when is_map(args) do
    %{conn: conn} = args
    input = args |> Map.delete([:conn, :access_token])

    change_user_author_response = case args do
      %{access_token: token} when not is_nil(token) ->
        make_query(conn, %{
            query: change_user_author_mutation(),
            variables: input
          },
          token
        )
      _ ->
        make_query(conn, %{
          query: change_user_author_mutation(),
          variables: input
        })
    end

    ~i(change_user_author_response.data.changeUserAuthor)
  end

  def delete_author(args \\ %{})
  def delete_author(args) when is_list(args) do
    args = args |> Enum.into(%{})

    delete_author(args)
  end

  def delete_author(args) when is_map(args) do
    %{conn: conn} = args
    input = args |> Map.delete([:conn, :access_token])

    delete_response = case args do
      %{access_token: token} when not is_nil(token) ->
        make_query(conn, %{
            query: delete_author_mutation(),
            variables: input
          },
          token
        )
      _ ->
        make_query(conn, %{
          query: delete_author_mutation(),
          variables: input
        })
    end

    ~i(delete_response.data.deleteAuthor)
  end

  def delete_user(args \\ %{})
  def delete_user(args) when is_list(args) do
    args = args |> Enum.into(%{})

    delete_user(args)
  end

  def delete_user(args) when is_map(args) do
    %{conn: conn} = args
    input = args |> Map.delete([:conn, :access_token])

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
