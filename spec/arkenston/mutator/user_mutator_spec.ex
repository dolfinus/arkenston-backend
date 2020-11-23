defmodule Arkenston.Mutator.UserMutatorSpec do
  import Arkenston.Factories.MainFactory
  alias Arkenston.Subject
  alias Arkenston.Repo
  import SubjectHelper
  use GraphqlHelper
  import Faker.Internet, only: [slug: 0, email: 0]
  import Faker.Lorem, only: [word: 0, sentence: 0, characters: 1]
  use ESpec, async: true
  import Indifferent.Sigils

  let :valid_attrs do
    %{password: "not_null", role: :user}
  end

  let :creator_user do
    user = build(:user)
    author = build(:author)

    {:ok, result} = Subject.create_author(author)
    {:ok, result} = Subject.create_user(user |> Map.put(:author_id, result.id))

    result = result |> Repo.preload(:author)

    %{author: author, user: user, id: result.id, access_token: auth(user, author, shared.conn)}
  end

  let :creator_moderator do
    user = build(:moderator)
    author = build(:author)

    {:ok, result} = Subject.create_author(author)
    {:ok, result} = Subject.create_user(user |> Map.put(:author_id, result.id))

    result = result |> Repo.preload(:author)

    %{author: author, user: user, id: result.id, access_token: auth(user, author, shared.conn)}
  end

  let :creator_admin do
    user = build(:admin)
    author = build(:author)

    {:ok, result} = Subject.create_author(author)
    {:ok, result} = Subject.create_user(user |> Map.put(:author_id, result.id))

    result = result |> Repo.preload(:author)

    %{author: author, user: user, id: result.id, access_token: auth(user, author, shared.conn)}
  end

  let :creator_anonymous do
    nil
  end

  let :creator do
    creator_admin()
  end

  context "mutator", module: :mutator, mutation: true do
    context "user", user: true do
      describe "createUser" do
        it "returns created user for valid attrs", validation: true, valid: true do
          user = build(:user)
          author = build(:author)

          create_response = create_user(input: prepare_user(user), author: prepare_author(author), conn: shared.conn)

          assert ~i(create_response.successful)
          assert check_user(~i(create_response.result), prepare_user(user) |> Map.put(:author, author))
        end

        it "returns error for unknown author id", validation: true, valid: false do
          invalid_user = build(:user)
          create_response = create_user(input: prepare_user(invalid_user), author: %{id: Ecto.UUID.generate()}, conn: shared.conn)

          refute ~i(create_response.successful)
        end

        it "returns error for already used author id", validation: true, valid: false do
          existing_user = build(:user)
          existing_author = build(:author)
          author_response = create_user(input: prepare_user(existing_user), author: prepare_author(existing_author), conn: shared.conn)

          invalid_user = build(:user)
          create_response = create_user(input: prepare_user(invalid_user), author: %{id: ~i(author_response.result.author.id)}, conn: shared.conn)

          refute ~i(create_response.successful)
        end

        it "returns error for already used author name", validation: true, valid: false do
          existing_user = build(:user)
          existing_author = build(:author)
          create_user(input: prepare_user(existing_user), author: prepare_author(existing_author), conn: shared.conn)

          invalid_user = build(:user)
          create_response = create_user(input: prepare_user(invalid_user), author: %{name: existing_author.name |> String.upcase()}, conn: shared.conn)

          refute ~i(create_response.successful)
        end

        it "returns error for already used author email", validation: true, valid: false do
          existing_user = build(:user)
          existing_author = build(:author)
          create_user(input: prepare_user(existing_user), author: prepare_author(existing_author), conn: shared.conn)

          invalid_user = build(:user)
          create_response = create_user(input: prepare_user(invalid_user), author: %{email: existing_author.email |> String.upcase()}, conn: shared.conn)

          refute ~i(create_response.successful)
        end

        it "returns error for empty password", validation: true, valid: false do
          user = build(:user)
          author = build(:author)

          create_response = create_user(input: prepare_user(user) |> Map.put(:password, ""), author: prepare_author(author), conn: shared.conn)
          refute ~i(create_response.successful)

          create_response = create_user(input: prepare_user(user) |> Map.put(:password, nil), author: prepare_author(author), conn: shared.conn)
          refute ~i(create_response.successful)
        end

        it "returns error for too short password", validation: true, valid: false do
          user = build(:user)
          author = build(:author)

          create_response = create_user(input: prepare_user(user) |> Map.put(:password, characters(1) |> to_string()), author: prepare_author(author), conn: shared.conn)
          refute ~i(create_response.successful)

          create_response = create_user(input: prepare_user(user) |> Map.put(:password, characters(5) |> to_string()), author: prepare_author(author), conn: shared.conn)
          refute ~i(create_response.successful)
        end

        it "accepts note for revision", audit: true do
          user = build(:user)
          author = build(:author)

          note = sentence()
          create_response = create_user(input: prepare_user(user) |> Map.merge(%{note: note}), author: prepare_author(author), conn: shared.conn)
          expect ~i(create_response.result.note) |> to(eq(note))
        end

        it "sets revision version to 1", audit: true do
          user = build(:user)
          author = build(:author)

          create_response = create_user(input: prepare_user(user), author: prepare_author(author), conn: shared.conn)

          expect ~i(create_response.result.version) |> to(eq(1))
        end

        it "sets created_by to non-nil if context is not empty", audit: true do
          user = build(:user)
          author = build(:author)

          %{access_token: access_token, id: creator_id} = creator()
          create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

          expect ~i(create_response.result.created_by.id) |> to(eq(creator_id))
        end

        it "sets created_by to nil if context is empty", audit: true, role: :anonymous do
          user = build(:user)
          author = build(:author)

          create_response = create_user(input: prepare_user(user), author: prepare_author(author), conn: shared.conn)

          expect ~i(create_response.result.created_by) |> to(be_nil())
        end

        it "sets created_at", audit: true do
          user = build(:user)
          author = build(:author)

          create_response = create_user(input: prepare_user(user), author: prepare_author(author), conn: shared.conn)

          expect ~i(create_response.result.created_at) |> not_to(be_nil())
        end

        [
          user:      [anonymous: true,  user: false, moderator: true,  admin: true],
          moderator: [anonymous: false, user: false, moderator: true,  admin: true],
          admin:     [anonymous: false, user: false, moderator: false, admin: true],
        ] |> Enum.each(fn({user_role, cols}) ->
          cols |> Enum.each(fn({role, is_allowed}) ->
              it "#{if is_allowed, do: "allows", else: "does not allow"} to create new #{user_role} by #{role}", permission: true, allow: is_allowed, role: role do
                user = build(unquote(user_role))
                author = build(:author)

                create_response = if unquote(role) == :anonymous do
                  create_user(input: prepare_user(user), author: prepare_author(author), conn: shared.conn)
                else
                  %{access_token: access_token} = unquote(:"creator_#{role}")()
                  create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)
                end

                if unquote(is_allowed) do
                  assert ~i(create_response.successful)
                else
                  refute ~i(create_response.successful)
                end
              end
          end)
        end)

        [
          user:      [user: false, moderator: true,  admin: true],
          moderator: [user: false, moderator: true,  admin: true],
          admin:     [user: false, moderator: false, admin: true],
        ] |> Enum.each(fn({user_role, cols}) ->
          cols |> Enum.each(fn({role, is_allowed}) ->
              it "#{if is_allowed, do: "allows", else: "does not allow"} to create new #{user_role} with custom author by #{role}", permission: true, allow: is_allowed, role: role do
                author = build(:author)
                %{access_token: access_token} = creator()
                create_author_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

                user = build(unquote(user_role))
                %{access_token: access_token} = unquote(:"creator_#{role}")()
                create_response = create_user(input: prepare_user(user), author: %{id: ~i(create_author_response.result.id)}, access_token: access_token, conn: shared.conn)

                if unquote(is_allowed) do
                  assert ~i(create_response.successful)
                else
                  refute ~i(create_response.successful)
                end
              end
          end)
        end)
      end

      describe "updateUser" do
        it "returns success for valid id", validation: true, valid: true do
          user = build(:user)
          author = build(:author)

          %{access_token: access_token} = creator()
          create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

          update_response = update_user(id: ~i(create_response.result.id), input: prepare_user(valid_attrs()), access_token: access_token, conn: shared.conn)

          assert ~i(update_response.successful)

          expected_user = prepare_user(user) |> Map.merge(valid_attrs()) |> Map.put(:author, author)
          assert check_user(~i(update_response.result), expected_user)
        end

        it "returns error for unknown id", validation: true, valid: false do
          %{access_token: access_token} = creator()
          update_response = update_user(id: Ecto.UUID.generate(), input: prepare_user(valid_attrs()), access_token: access_token, conn: shared.conn)

          refute ~i(update_response.successful)
        end

        it "returns success for valid name", validation: true, valid: true do
          user = build(:user)
          author = build(:author)

          %{access_token: access_token} = creator()
          create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

          update_response = update_user(name: author.name |> String.upcase(), input: prepare_user(valid_attrs()), access_token: access_token, conn: shared.conn)

          assert ~i(update_response.successful)

          expected_user = prepare_user(user) |> Map.merge(valid_attrs()) |> Map.put(:author, author)
          assert check_user(~i(update_response.result), expected_user)
        end

        it "returns error for unknown name", validation: true, valid: true do
          author = build(:author)

          %{access_token: access_token} = creator()

          update_response = update_user(name: author.name |> String.upcase(), input: prepare_user(valid_attrs()), access_token: access_token, conn: shared.conn)

          refute ~i(update_response.successful)
        end

        it "returns success for valid email", validation: true, valid: true do
          user = build(:user)
          author = build(:author)

          %{access_token: access_token} = creator()
          create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

          update_response = update_user(email: author.email |> String.upcase(), input: prepare_user(valid_attrs()), access_token: access_token, conn: shared.conn)

          assert ~i(update_response.successful)

          expected_user = prepare_user(user) |> Map.merge(valid_attrs()) |> Map.put(:author, author)
          assert check_user(~i(update_response.result), expected_user)
        end

        it "returns error for unknown email", validation: true, valid: true do
          author = build(:author)

          %{access_token: access_token} = creator()

          update_response = update_user(email: author.email |> String.upcase(), input: prepare_user(valid_attrs()), access_token: access_token, conn: shared.conn)

          refute ~i(update_response.successful)
        end

        it "returns error for too short password", validation: true, valid: false do
          user = build(:user)
          author = build(:author)

          %{access_token: access_token} = creator()
          create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

          update_response = update_user(id: ~i(create_response.result.id), input: %{password: characters(1) |> to_string()}, access_token: access_token, conn: shared.conn)
          refute ~i(update_response.successful)

          update_response = update_user(id: ~i(create_response.result.id), input: %{password: characters(5) |> to_string()}, access_token: access_token, conn: shared.conn)
          refute ~i(update_response.successful)
        end

        it "returns success for current user", validation: true, valid: true do
          user = build(:user)
          author = build(:author)

          %{access_token: access_token} = creator()
          create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

          access_token = auth(user, author, shared.conn)
          update_response = update_user(input: prepare_user(valid_attrs()), access_token: access_token, conn: shared.conn)

          assert ~i(update_response.successful)
          expected_user = prepare_user(user) |> Map.merge(valid_attrs()) |> Map.put(:author, author)
          assert check_user(~i(update_response.result), expected_user)
        end

        it "returns error for anonymous user", validation: true, valid: false do
          user = build(:user)
          author = build(:author)

          %{access_token: access_token} = creator()
          create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

          update_response = update_user(id: ~i(create_response.result.id), input: prepare_user(valid_attrs()), conn: shared.conn)

          refute ~i(update_response.successful)
        end

        it "returns error for already deleted user", validation: true, valid: false do
          user = build(:user)
          author = build(:author)

          %{access_token: access_token} = creator()
          create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)
          delete_user(id: ~i(create_response.result.id), access_token: access_token, conn: shared.conn)

          update_response = update_user(id: ~i(create_response.result.id), input: prepare_user(valid_attrs()), access_token: access_token, conn: shared.conn)

          refute ~i(update_response.successful)
        end

        it "accepts note for revision", audit: true do
          user = build(:user)
          author = build(:author)

          %{access_token: access_token} = creator()
          create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

          note = sentence()
          update_response = update_user(id: ~i(create_response.result.id), input: %{note: note}, access_token: access_token, conn: shared.conn)

          expect ~i(update_response.result.note) |> to(eq(note))
        end

        it "increments revision version", audit: true do
          user = build(:user)
          author = build(:author)

          %{access_token: access_token} = creator()
          create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)
          update_response = update_user(id: ~i(create_response.result.id), input: prepare_user(valid_attrs()), access_token: access_token, conn: shared.conn)

          expect ~i(update_response.result.version) |> to(be(:>, ~i(create_response.result.version)))
        end

        it "sets updated_by to non-nil if context is not empty", audit: true do
          user = build(:user)
          author = build(:author)

          %{access_token: access_token, id: updator_id} = creator()
          create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)
          update_response = update_user(id: ~i(create_response.result.id), input: prepare_user(valid_attrs()), access_token: access_token, conn: shared.conn)

          expect ~i(update_response.result.updated_by.id) |> to(eq(updator_id))
        end

        it "does not touch created_at", audit: true do
          user = build(:user)
          author = build(:author)

          %{access_token: access_token} = creator()
          create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)
          update_response = update_user(id: ~i(create_response.result.id), input: prepare_user(valid_attrs()), access_token: access_token, conn: shared.conn)

          expect ~i(update_response.result.created_at) |> to(eq(~i(create_response.result.created_at)))
        end

        it "touches updated_at", audit: true do
          user = build(:user)
          author = build(:author)

          %{access_token: access_token} = creator()
          create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)
          update_response = update_user(id: ~i(create_response.result.id), input: prepare_user(valid_attrs()), access_token: access_token, conn: shared.conn)

          expect ~i(create_response.result.updated_at) |> to(be_nil())
          expect ~i(update_response.result.updated_at) |> not_to(be_nil())
        end

        [:user, :moderator, :admin]
        |> Enum.each(fn(user_role) ->
          it "allows #{user_role} to update himself", permission: true, allow: true, self: true do
            user = build(unquote(user_role))
            author = build(:author)

            %{access_token: access_token} = creator()
            create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

            note = word()
            access_token = auth(user, author, shared.conn)
            update_response = update_user(id: ~i(create_response.result.id), input: %{note: note}, access_token: access_token, conn: shared.conn)

            assert ~i(update_response.successful)
          end
        end)

        [
          user:      [user: false, moderator: true,  admin: true],
          moderator: [user: false, moderator: true,  admin: true],
          admin:     [user: false, moderator: false, admin: true],
        ] |> Enum.each(fn({user_role, cols}) ->
          cols |> Enum.each(fn({role, is_allowed}) ->
              it "#{if is_allowed, do: "allows", else: "does not allow"} #{role} to update #{user_role}", permission: true, allow: is_allowed, role: user_role do
                user = build(unquote(user_role))
                author = build(:author)

                %{access_token: access_token} = creator()
                create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

                note = word()
                %{access_token: access_token} = unquote(:"creator_#{role}")()
                update_response = update_user(id: ~i(create_response.result.id), input: %{note: note}, access_token: access_token, conn: shared.conn)

                if unquote(is_allowed) do
                  assert ~i(update_response.successful)
                else
                  refute ~i(update_response.successful)
                end
              end
          end)
        end)

        [:user, :moderator, :admin]
        |> Enum.each(fn(user_role) ->
          it "allows to change #{user_role} password by himself", permission: true, allow: true, self: true do
            user = build(unquote(user_role))
            author = build(:author)

            %{access_token: access_token} = creator()
            create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

            password = characters(6) |> to_string()
            access_token = auth(user, author, shared.conn)
            update_response = update_user(id: ~i(create_response.result.id), input: %{password: password}, access_token: access_token, conn: shared.conn)

            assert ~i(update_response.successful)
          end
        end)

        [
          user:      [user: false, moderator: true,  admin: true],
          moderator: [user: false, moderator: false, admin: true],
          admin:     [user: false, moderator: false, admin: false],
        ] |> Enum.each(fn({user_role, cols}) ->
          cols |> Enum.each(fn({role, is_allowed}) ->
            it "#{if is_allowed, do: "allows", else: "does not allow"} #{role} to change #{user_role} password", permission: true, allow: is_allowed, role: role do
              user = build(unquote(user_role))
              author = build(:author)

              %{access_token: access_token} = creator()
              create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

              password = characters(6) |> to_string()
              %{access_token: access_token} = unquote(:"creator_#{role}")()
              update_response = update_user(id: ~i(create_response.result.id), input: %{password: password}, access_token: access_token, conn: shared.conn)

              if unquote(is_allowed) do
                assert ~i(update_response.successful)
              else
                refute ~i(update_response.successful)
              end
            end
          end)
        end)

        [
          user: [:moderator, :admin],
          moderator: [:admin]
        ] |> Enum.each(fn({user_role, roles}) ->
          roles |> Enum.each(fn(target_role) ->
            it "does not allow #{user_role} to upgrade his role to #{target_role}", permission: true, allow: false, self: true do
              user = build(unquote(user_role))
              author = build(:author)

              %{access_token: access_token} = creator()
              create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

              access_token = auth(user, author, shared.conn)
              update_response = update_user(id: ~i(create_response.result.id), input: prepare_user(%{role: unquote(target_role)}), access_token: access_token, conn: shared.conn)

              refute ~i(update_response.successful)
            end
          end)
        end)

        [
          user: [
            moderator: [user: false, moderator: true,  admin: true],
            admin:     [user: false, moderator: false, admin: true],
          ],
          moderator: [
            admin:     [user: false, moderator: false, admin: true],
          ]
        ] |> Enum.each(fn({user_role, cols}) ->
          cols |> Enum.each(fn({target_role, col}) ->
            col |> Enum.each(fn({role, is_allowed}) ->
              it "#{if is_allowed, do: "allows", else: "does not allow"} #{role} to upgrade #{user_role} to #{target_role}", permission: true, allow: is_allowed, role: role do
                user = build(unquote(user_role))
                author = build(:author)

                %{access_token: access_token} = creator()
                create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

                %{access_token: access_token} = unquote(:"creator_#{role}")()
                update_response = update_user(id: ~i(create_response.result.id), input: prepare_user(%{role: unquote(target_role)}), access_token: access_token, conn: shared.conn)

                if unquote(is_allowed) do
                  assert ~i(update_response.successful)
                else
                  refute ~i(update_response.successful)
                end
              end
            end)
          end)
        end)

        [
          moderator: [:user],
          admin: [:user, :moderator]
        ] |> Enum.each(fn({user_role, target_roles}) ->
          target_roles |> Enum.each(fn(target_role) ->
            it "does not allow #{user_role} to downgrade his role to #{target_role}", permission: true, allow: false, self: true do
              user = build(unquote(user_role))
              author = build(:author)

              %{access_token: access_token} = creator()
              create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

              access_token = auth(user, author, shared.conn)
              update_response = update_user(id: ~i(create_response.result.id), input: prepare_user(%{role: unquote(target_role)}), access_token: access_token, conn: shared.conn)

              refute ~i(update_response.successful)
            end
          end)
        end)

        [
          moderator: [
            user:      [user: false, moderator: false, admin: true],
          ],
          admin: [
            user:      [user: false, moderator: false, admin: false],
            moderator: [user: false, moderator: false, admin: false],
          ]
        ] |> Enum.each(fn({user_role, cols}) ->
          cols |> Enum.each(fn({target_role, col}) ->
            col |> Enum.each(fn({role, is_allowed}) ->
              it "#{if is_allowed, do: "allows", else: "does not allow"} #{role} to downgrade #{user_role} to #{target_role}", permission: true, allow: is_allowed, role: user_role do
                user = build(unquote(user_role))
                author = build(:author)

                %{access_token: access_token} = creator()
                create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

                %{access_token: access_token} = unquote(:"creator_#{role}")()
                update_response = update_user(id: ~i(create_response.result.id), input: prepare_user(%{role: unquote(target_role)}), access_token: access_token, conn: shared.conn)

                if unquote(is_allowed) do
                  assert ~i(update_response.successful)
                else
                  refute ~i(update_response.successful)
                end
              end
            end)
          end)
        end)
      end

      describe "changeUserAuthor" do
        it "returns success for valid user id", validation: true, valid: true do
          existing_user = build(:user)
          existing_author = build(:author)

          %{access_token: access_token} = creator()
          create_user_response = create_user(input: prepare_user(existing_user), author: prepare_author(existing_author), access_token: access_token, conn: shared.conn)

          author = build(:author)
          %{access_token: access_token} = creator()
          create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

          change_user_author_response = change_user_author(id: ~i(create_user_response.result.id), author: %{id: ~i(create_response.result.id)}, access_token: access_token, conn: shared.conn)

          assert ~i(change_user_author_response.successful)
          assert check_author(~i(change_user_author_response.result.author), ~i(create_response.result))
        end

        it "returns success for unknown user id", validation: true, valid: false do
          author = build(:author)
          %{access_token: access_token} = creator()
          create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

          change_user_author_response = change_user_author(id: Ecto.UUID.generate(), author: %{id: ~i(create_response.result.id)}, access_token: access_token, conn: shared.conn)

          refute ~i(change_user_author_response.successful)
        end

        it "returns success for valid user name", validation: true, valid: true do
          existing_user = build(:user)
          existing_author = build(:author)

          %{access_token: access_token} = creator()
          create_user(input: prepare_user(existing_user), author: prepare_author(existing_author), access_token: access_token, conn: shared.conn)

          author = build(:author)
          %{access_token: access_token} = creator()
          create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

          change_user_author_response = change_user_author(name: existing_author.name |> String.upcase(), author: %{id: ~i(create_response.result.id)}, access_token: access_token, conn: shared.conn)

          assert ~i(change_user_author_response.successful)
          assert check_author(~i(change_user_author_response.result.author), ~i(create_response.result))
        end

        it "returns success for unknown user name", validation: true, valid: false do
          author = build(:author)
          %{access_token: access_token} = creator()
          create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

          change_user_author_response = change_user_author(name: slug(), author: %{id: ~i(create_response.result.id)}, access_token: access_token, conn: shared.conn)

          refute ~i(change_user_author_response.successful)
        end

        it "returns success for valid author id", validation: true, valid: true do
          existing_user = build(:user)
          existing_author = build(:author)

          %{access_token: access_token} = creator()
          create_user_response = create_user(input: prepare_user(existing_user), author: prepare_author(existing_author), access_token: access_token, conn: shared.conn)

          author = build(:author)
          %{access_token: access_token} = creator()
          create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

          change_user_author_response = change_user_author(id: ~i(create_user_response.result.id), author: %{id: ~i(create_response.result.id)}, access_token: access_token, conn: shared.conn)

          assert ~i(change_user_author_response.successful)
          assert check_author(~i(change_user_author_response.result.author), ~i(create_response.result))
        end

        it "returns error for unknown author id", validation: true, valid: false do
          user = build(:user)
          author = build(:author)

          %{access_token: access_token} = creator()
          create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

          change_user_author_response = change_user_author(id: ~i(create_response.result.id), author: %{id: Ecto.UUID.generate()}, access_token: access_token, conn: shared.conn)

          refute ~i(change_user_author_response.successful)
        end

        it "returns error for already used author id", validation: true, valid: false do
          existing_user = build(:user)
          existing_author = build(:author)

          %{access_token: access_token} = creator()
          author_response = create_user(input: prepare_user(existing_user), author: prepare_author(existing_author), access_token: access_token, conn: shared.conn)

          user = build(:user)
          author = build(:author)

          %{access_token: access_token} = creator()
          create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

          change_user_author_response = change_user_author(id: ~i(create_response.result.id), author: %{id: ~i(author_response.result.author.id)}, access_token: access_token, conn: shared.conn)

          refute ~i(change_user_author_response.successful)
        end

        it "returns success for valid author name", validation: true, valid: true do
          existing_user = build(:user)
          existing_author = build(:author)

          %{access_token: access_token} = creator()
          create_user_response = create_user(input: prepare_user(existing_user), author: prepare_author(existing_author), access_token: access_token, conn: shared.conn)

          author = build(:author)
          %{access_token: access_token} = creator()
          create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

          change_user_author_response = change_user_author(id: ~i(create_user_response.result.id), author: %{name: author.name |> String.upcase()}, access_token: access_token, conn: shared.conn)

          assert ~i(change_user_author_response.successful)
          assert check_author(~i(change_user_author_response.result.author), ~i(create_response.result))
        end

        it "returns error for unknown author name", validation: true, valid: false do
          user = build(:user)
          author = build(:author)

          %{access_token: access_token} = creator()
          create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

          name = slug()
          change_user_author_response = change_user_author(id: ~i(create_response.result.id), author: %{name: name}, access_token: access_token, conn: shared.conn)

          refute ~i(change_user_author_response.successful)
        end

        it "returns error for already used author name", validation: true, valid: false do
          existing_user = build(:user)
          existing_author = build(:author)

          %{access_token: access_token} = creator()
          create_user(input: prepare_user(existing_user), author: prepare_author(existing_author), access_token: access_token, conn: shared.conn)

          user = build(:user)
          author = build(:author)

          %{access_token: access_token} = creator()
          create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

          change_user_author_response = change_user_author(id: ~i(create_response.result.id), author: %{name: existing_author.name |> String.upcase()}, access_token: access_token, conn: shared.conn)

          refute ~i(change_user_author_response.successful)
        end

        it "returns success for valid author email", validation: true, valid: true do
          existing_user = build(:user)
          existing_author = build(:author)

          %{access_token: access_token} = creator()
          create_user_response = create_user(input: prepare_user(existing_user), author: prepare_author(existing_author), access_token: access_token, conn: shared.conn)

          author = build(:author)
          %{access_token: access_token} = creator()
          create_response = create_author(input: prepare_author(author), access_token: access_token, conn: shared.conn)

          change_user_author_response = change_user_author(id: ~i(create_user_response.result.id), author: %{email: author.email |> String.upcase()}, access_token: access_token, conn: shared.conn)

          assert ~i(change_user_author_response.successful)
          assert check_author(~i(change_user_author_response.result.author), ~i(create_response.result))
        end

        it "returns error for unknown author email", validation: true, valid: false do
          user = build(:user)
          author = build(:author)

          %{access_token: access_token} = creator()
          create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

          email = email()
          change_user_author_response = change_user_author(id: ~i(create_response.result.id), author: %{email: email}, access_token: access_token, conn: shared.conn)

          refute ~i(change_user_author_response.successful)
        end

        it "returns error for already used author email", validation: true, valid: false do
          existing_user = build(:user)
          existing_author = build(:author)

          %{access_token: access_token} = creator()
          create_user(input: prepare_user(existing_user), author: prepare_author(existing_author), access_token: access_token, conn: shared.conn)

          user = build(:user)
          author = build(:author)

          %{access_token: access_token} = creator()
          create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

          change_user_author_response = change_user_author(id: ~i(create_response.result.id), author: %{email: existing_author.email |> String.upcase()}, access_token: access_token, conn: shared.conn)

          refute ~i(change_user_author_response.successful)
        end

        [
          user:      false,
          moderator: true,
          admin:     true
        ] |> Enum.each(fn({user_role, is_allowed}) ->
          it "#{if is_allowed, do: "allows", else: "does not allow"} #{user_role} to change his author", permission: true, allow: is_allowed, self: true do
            user = build(unquote(user_role))
            author = build(:author)

            %{access_token: access_token} = creator()
            create_user_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

            new_author = build(:author)
            create_response = create_author(input: prepare_author(new_author), access_token: access_token, conn: shared.conn)

            access_token = auth(user, author, shared.conn)
            change_user_author_response = change_user_author(id: ~i(create_user_response.result.id), author: %{id: ~i(create_response.result.id)}, access_token: access_token, conn: shared.conn)

            if unquote(is_allowed) do
              assert ~i(change_user_author_response.successful)
            else
              refute ~i(change_user_author_response.successful)
            end
          end
        end)

        [
          user:      [user: false, moderator: true,   admin: true],
          moderator: [user: false, moderator: false,  admin: true],
          admin:     [user: false, moderator: false,  admin: false],
        ] |> Enum.each(fn({user_role, cols}) ->
            cols |> Enum.each(fn({role, is_allowed}) ->
              it "#{if is_allowed, do: "allows", else: "does not allow"} #{role} to change #{user_role} author", permission: true, allow: is_allowed, role: user_role do
                user = build(unquote(user_role))
                author = build(:author)

                %{access_token: access_token} = creator()
                create_user_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

                new_author = build(:author)
                create_response = create_author(input: prepare_author(new_author), access_token: access_token, conn: shared.conn)

                %{access_token: access_token} = unquote(:"creator_#{role}")()
                change_user_author_response = change_user_author(id: ~i(create_user_response.result.id), author: %{id: ~i(create_response.result.id)}, access_token: access_token, conn: shared.conn)

                if unquote(is_allowed) do
                  assert ~i(change_user_author_response.successful)
                else
                  refute ~i(change_user_author_response.successful)
                end
              end
          end)
        end)
      end

      describe "deleteUser" do
        it "returns success for valid id", validation: true, valid: true do
          user = build(:user)
          author = build(:author)

          %{access_token: access_token} = creator()
          create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)
          delete_response = delete_user(id: ~i(create_response.result.id), access_token: access_token, conn: shared.conn)

          assert ~i(delete_response.successful)
          expect ~i(delete_response.result) |> to(be_nil())
        end

        it "returns error for unknown id", validation: true, valid: false do
          %{access_token: access_token} = creator()
          delete_response = delete_user(id: Ecto.UUID.generate(), access_token: access_token, conn: shared.conn)

          refute ~i(delete_response.successful)
        end

        it "returns success for valid name", validation: true, valid: true do
          user = build(:user)
          author = build(:author)

          %{access_token: access_token} = creator()
          create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)
          delete_response = delete_user(name: author.name |> String.upcase(), access_token: access_token, conn: shared.conn)

          assert ~i(delete_response.successful)
          expect ~i(delete_response.result) |> to(be_nil())
        end

        it "returns error for unknown name", validation: true, valid: false do
          author = build(:author)

          %{access_token: access_token} = creator()
          delete_response = delete_user(name: author.name, access_token: access_token, conn: shared.conn)

          refute ~i(delete_response.successful)
        end

        it "returns success for valid email", validation: true, valid: true do
          user = build(:user)
          author = build(:author)

          %{access_token: access_token} = creator()
          create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)
          delete_response = delete_user(email: author.email |> String.upcase(), access_token: access_token, conn: shared.conn)

          assert ~i(delete_response.successful)
          expect ~i(delete_response.result) |> to(be_nil())
        end

        it "returns error for unknown email", validation: true, valid: false do
          author = build(:author)

          %{access_token: access_token} = creator()
          delete_response = delete_user(email: author.email, access_token: access_token, conn: shared.conn)

          refute ~i(delete_response.successful)
        end

        it "returns success for current user", validation: true, valid: true, self: true do
          user = build(:user)
          author = build(:author)

          %{access_token: access_token} = creator()
          create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

          access_token = auth(user, author, shared.conn)
          delete_response = delete_user(access_token: access_token, conn: shared.conn)

          assert ~i(delete_response.successful)
          expect ~i(delete_response.result) |> to(be_nil())
        end

        it "returns error for anonymous user", validation: true, valid: false do
          user = build(:user)
          author = build(:author)

          create_response = create_user(input: prepare_user(user), author: prepare_author(author), conn: shared.conn)
          delete_response = delete_user(id: ~i(create_response.result.id), conn: shared.conn)

          refute ~i(delete_response.successful)
        end

        it "accepts note for revision", audit: true do
          user = build(:user)
          author = build(:author)

          %{access_token: access_token} = creator()
          create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

          note = sentence()
          delete_response = delete_user(id: ~i(create_response.result.id), input: %{note: note}, access_token: access_token, conn: shared.conn)

          assert ~i(delete_response.successful)
        end

        [:user, :moderator, :admin]
        |> Enum.each(fn(user_role) ->
          it "allows #{user_role} to delete himself", permission: true, allow: true, self: true do
            user = build(unquote(user_role))
            author = build(:author)

            %{access_token: access_token} = creator()
            create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

            access_token = auth(user, author, shared.conn)
            delete_response = delete_user(id: ~i(create_response.result.id), input: %{with_author: false}, access_token: access_token, conn: shared.conn)

            assert ~i(delete_response.successful)

            get_user_response = get_user(id: ~i(create_response.result.id), conn: shared.conn)
            refute ~i(get_user_response.data.user)

            get_author_response = get_author(id: ~i(create_response.result.author.id), conn: shared.conn)
            assert ~i(get_author_response.data.author)
          end
        end)

        [:user, :moderator, :admin]
        |> Enum.each(fn(user_role) ->
          it "allows #{user_role} to delete himself with author", permission: true, allow: true, self: true do
            user = build(unquote(user_role))
            author = build(:author)

            %{access_token: access_token} = creator()
            create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

            access_token = auth(user, author, shared.conn)
            delete_response = delete_user(id: ~i(create_response.result.id), access_token: access_token, conn: shared.conn)

            assert ~i(delete_response.successful)

            get_user_response = get_user(id: ~i(create_response.result.id), conn: shared.conn)
            refute ~i(get_user_response.data.user)

            get_author_response = get_author(id: ~i(create_response.result.author.id), conn: shared.conn)
            refute ~i(get_author_response.data.author)
          end
        end)

        [
          user:      [user: false, moderator: true,   admin: true],
          moderator: [user: false, moderator: false,  admin: true],
          admin:     [user: false, moderator: false,  admin: false],
        ] |> Enum.each(fn({user_role, cols}) ->
            cols |> Enum.each(fn({role, is_allowed}) ->
              it "#{if is_allowed, do: "allows", else: "does not allow"} #{role} to delete #{user_role}", permission: true, allow: is_allowed, role: user_role do
                user = build(unquote(user_role))
                author = build(:author)

                %{access_token: access_token} = creator()
                create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

                %{access_token: access_token} = unquote(:"creator_#{role}")()
                delete_response = delete_user(id: ~i(create_response.result.id), input: %{with_author: false}, access_token: access_token, conn: shared.conn)

                if unquote(is_allowed) do
                  assert ~i(delete_response.successful)

                  get_user_response = get_user(id: ~i(create_response.result.id), conn: shared.conn)
                  refute ~i(get_user_response.data.user)

                  get_author_response = get_author(id: ~i(create_response.result.author.id), conn: shared.conn)
                  assert ~i(get_author_response.data.author)
                else
                  refute ~i(delete_response.successful)
                end
              end
            end)
          end)

        [
          user:      [user: false, moderator: true,   admin: true],
          moderator: [user: false, moderator: false,  admin: true],
          admin:     [user: false, moderator: false,  admin: false],
        ] |> Enum.each(fn({user_role, cols}) ->
            cols |> Enum.each(fn({role, is_allowed}) ->
              it "#{if is_allowed, do: "allows", else: "does not allow"} #{role} to delete #{user_role} with author", permission: true, allow: is_allowed, role: user_role do
                user = build(unquote(user_role))
                author = build(:author)

                %{access_token: access_token} = creator()
                create_response = create_user(input: prepare_user(user), author: prepare_author(author), access_token: access_token, conn: shared.conn)

                %{access_token: access_token} = unquote(:"creator_#{role}")()
                delete_response = delete_user(id: ~i(create_response.result.id), access_token: access_token, conn: shared.conn)

                if unquote(is_allowed) do
                  assert ~i(delete_response.successful)

                  get_user_response = get_user(id: ~i(create_response.result.id), conn: shared.conn)
                  refute ~i(get_user_response.data.user)

                  get_author_response = get_author(id: ~i(create_response.result.author.id), conn: shared.conn)
                  refute ~i(get_author_response.data.author)
                else
                  refute ~i(delete_response.successful)
                end
              end
            end)
          end)
      end
    end
  end
end
