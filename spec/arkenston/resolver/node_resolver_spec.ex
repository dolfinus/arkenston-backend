defmodule Arkenston.Resolver.NodeResolverSpec do
  import Arkenston.Factories.UserFactory
  alias Arkenston.Subject
  import SubjectHelper
  import NodeHelper
  use GraphqlHelper
  use ESpec, async: true
  import Indifferent.Sigils

  let :author do
    user = build(:admin)
    {:ok, result} = Subject.create_user(user)

    %{user: user, id: result.id, access_token: auth(user, shared.conn)}
  end

  context "resolver", module: :resolver, query: true do
    context "nodes", nodes: true, node: true do
      describe "node" do
        it "with user id return user" do
          %{access_token: access_token} = author()

          user = build(:user)
          create_response = create_user(input: prepare_user(user), access_token: access_token, conn: shared.conn)
          created_user = ~i(create_response.result)

          node_response = get_node(id: ~i(created_user.id), access_token: access_token, conn: shared.conn)

          expect node_response |> not_to(be_nil())
          expect ~i(node_response.__typename) |> to(eq("User"))
          assert check_user(node_response, user)
        end
      end
    end
  end
end
