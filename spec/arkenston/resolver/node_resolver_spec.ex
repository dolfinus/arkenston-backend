defmodule Arkenston.Resolver.NodeResolverSpec do
  import Arkenston.Factories.MainFactory
  alias Arkenston.Subject
  alias Arkenston.Repo
  import Arkenston.Helper.UUID
  import SubjectHelper
  import NodeHelper
  use GraphqlHelper
  use ESpec, async: true
  import Indifferent.Sigils

  let :creator do
    user = build(:admin)
    author = build(:author)

    {:ok, result} = Subject.create_author(author)
    {:ok, result} = Subject.create_user(user |> Map.put(:author_id, result.id))

    result = result |> Repo.preload(:author)

    %{author: author, user: user, id: result.id, access_token: auth(user, author, shared.conn)}
  end

  context "resolver", module: :resolver, query: true do
    context "nodes", nodes: true, node: true do
      describe "node" do
        it "return user for user id" do
          %{access_token: access_token} = creator()

          user = build(:user)
          author = build(:author)

          create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)
          created_user = ~i(create_response.result)

          node_response = get_node(id: ~i(created_user.id), access_token: access_token, conn: shared.conn)

          expect node_response |> not_to(be_nil())
          expect ~i(node_response.__typename) |> to(eq("User"))
          assert check_user(node_response, user)
        end

        it "return author for author id" do
          %{access_token: access_token} = creator()

          author = build(:author)

          create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)
          created_author = ~i(create_response.result)

          node_response = get_node(id: ~i(created_author.id), access_token: access_token, conn: shared.conn)

          expect node_response |> not_to(be_nil())
          expect ~i(node_response.__typename) |> to(eq("Author"))
          assert check_user(node_response, author)
        end

        it "return error for unknown id" do
          node_response = get_node(id: domain_uuid(:user), conn: shared.conn)
          expect node_response |> to(be_nil())

          node_response = get_node(id: domain_uuid(:author), conn: shared.conn)
          expect node_response |> to(be_nil())
        end
      end
    end
  end
end
