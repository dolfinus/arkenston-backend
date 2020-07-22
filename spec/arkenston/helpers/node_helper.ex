defmodule NodeHelper do
  use GraphqlHelper
  import Indifferent.Sigils

  def get_node_query() do
    """
    query ($id: ID!){
      node(id: $id) {
        id
        __typename
        ... on User {
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
    }
    """
  end

  def get_node(args) when is_list(args) do
    args = args |> Enum.into(%{})

    get_node(args)
  end

  def get_node(args) when is_map(args) do
    %{conn: conn} = args
    input = args |> Map.delete([:conn, :access_token])

    get_node_response = case args do
      %{access_token: token} when not is_nil(token) ->
        make_query(conn, %{
            query: get_node_query(),
            variables: input
          },
          token
        )
      _ ->
        make_query(conn, %{
          query: get_node_query(),
          variables: input
        })
    end

    ~i(get_node_response.data.node)
  end
end
