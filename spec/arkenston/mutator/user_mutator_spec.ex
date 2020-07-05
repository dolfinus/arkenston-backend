defmodule Arkenston.Mutator.UserMutatorSpec do
  import Arkenston.Factories.UserFactory
  alias Arkenston.Subject
  import SubjectHelper
  use GraphqlHelper
  import Faker.Lorem, only: [word: 0, sentence: 0]
  use ESpec, async: true
  import Indifferent.Sigils

  @valid_attrs %{name: "text", password: "not_null", email: "it@example.com", role: :user}

  let :author_user do
    user = build(:user)
    {:ok, result} = Subject.create_user(user)

    %{user: user, id: result.id, access_token: auth(user, shared.conn)}
  end

  let :author_moderator do
    user = build(:moderator)
    {:ok, result} = Subject.create_user(user)

    %{user: user, id: result.id, access_token: auth(user, shared.conn)}
  end

  let :author_admin do
    user = build(:admin)
    {:ok, result} = Subject.create_user(user)

    %{user: user, id: result.id, access_token: auth(user, shared.conn)}
  end

  let :author_anonymous do
    nil
  end

  let :author do
    author_admin()
  end

  context "mutator", module: :mutator, mutation: true do
    context "user", user: true do
      describe "createUser" do
        it "returns created user for valid attrs", validation: true, valid: true do
          user = build(:user)
          create_response = create_user(input: prepare_user(user), conn: shared.conn)

          assert ~i(create_response.successful)
          assert check_user(~i(create_response.result), user)
        end

        it "returns error for invalid attrs", validation: true, valid: false do
          existing_user = build(:user)
          create_user(input: prepare_user(existing_user), conn: shared.conn)

          invalid_user = build(:user, name: existing_user.name, email: existing_user.email)
          create_response = create_user(input: prepare_user(invalid_user), conn: shared.conn)

          refute ~i(create_response.successful)
        end

        it "accepts note for revision", audit: true do
          note = sentence()
          user_with_note = build(:user)

          create_response = create_user(input: prepare_user(user_with_note) |> Map.merge(%{note: note}), conn: shared.conn)
          expect ~i(create_response.result.note) |> to(eq(note))
        end

        it "sets revision version to 1", audit: true do
          user = build(:user)
          create_response = create_user(input: prepare_user(user), conn: shared.conn)

          expect ~i(create_response.result.version) |> to(eq(1))
        end

        it "sets created_by to non-nil if context is not empty", audit: true do
          user = build(:user)
          %{access_token: access_token, id: creator_id} = author()
          create_response = create_user(input: prepare_user(user), access_token: access_token, conn: shared.conn)

          expect ~i(create_response.result.created_by.id) |> to(eq(creator_id))
        end

        it "sets created_by to nil if context is empty", audit: true, role: :anonymous do
          user = build(:user)
          create_response = create_user(input: prepare_user(user), conn: shared.conn)

          expect ~i(create_response.result.created_by) |> to(be_nil())
        end

        it "sets created_at", audit: true do
          user = build(:user)
          create_response = create_user(input: prepare_user(user), conn: shared.conn)

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

                create_response = if unquote(role) == :anonymous do
                  create_user(input: prepare_user(user), conn: shared.conn)
                else
                  %{access_token: access_token} = unquote(:"author_#{role}")()
                  create_user(input: prepare_user(user), access_token: access_token, conn: shared.conn)
                end

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
          %{access_token: access_token} = author()
          create_response = create_user(input: prepare_user(user), access_token: access_token, conn: shared.conn)
          update_response = update_user(id: ~i(create_response.result.id), input: prepare_user(@valid_attrs), access_token: access_token, conn: shared.conn)

          assert ~i(update_response.successful)

          expected_user = user |> Map.merge(@valid_attrs)
          assert check_user(~i(update_response.result), expected_user)
        end

        it "returns error for unknown id", validation: true, valid: false do
          %{access_token: access_token} = author()
          update_response = update_user(id: Ecto.UUID.generate(), input: prepare_user(@valid_attrs), access_token: access_token, conn: shared.conn)

          refute ~i(update_response.successful)
        end

        it "returns success for valid name", validation: true, valid: true do
          user = build(:user)
          %{access_token: access_token} = author()
          create_user(input: prepare_user(user), access_token: access_token, conn: shared.conn)
          update_response = update_user(name: user.name, input: prepare_user(@valid_attrs), access_token: access_token, conn: shared.conn)

          assert ~i(update_response.successful)

          expected_user = user |> Map.merge(@valid_attrs)
          assert check_user(~i(update_response.result), expected_user)
        end

        it "returns error for unknown name", validation: true, valid: false do
          user = build(:user)
          %{access_token: access_token} = author()
          update_response = update_user(name: user.name, input: prepare_user(@valid_attrs), access_token: access_token, conn: shared.conn)

          refute ~i(update_response.successful)
        end

        it "returns success for valid email", validation: true, valid: true do
          user = build(:user)
          %{access_token: access_token} = author()
          create_user(input: prepare_user(user), access_token: access_token, conn: shared.conn)
          update_response = update_user(email: user.email, input: prepare_user(@valid_attrs), access_token: access_token, conn: shared.conn)

          assert ~i(update_response.successful)

          expected_user = user |> Map.merge(@valid_attrs)
          assert check_user(~i(update_response.result), expected_user)
        end

        it "returns error for unknown email", validation: true, valid: false do
          user = build(:user)
          %{access_token: access_token} = author()
          update_response = update_user(email: user.email, input: prepare_user(@valid_attrs), access_token: access_token, conn: shared.conn)

          refute ~i(update_response.successful)
        end

        it "returns success for current user", validation: true, valid: true do
          user = build(:user)
          %{access_token: access_token} = author()
          create_user(input: prepare_user(user), access_token: access_token, conn: shared.conn)

          access_token = auth(user, shared.conn)
          update_response = update_user(input: prepare_user(@valid_attrs), access_token: access_token, conn: shared.conn)

          assert ~i(update_response.successful)
          expected_user = user |> Map.merge(@valid_attrs)
          assert check_user(~i(update_response.result), expected_user)
        end

        it "returns error for invalid attrs", validation: true, valid: false do
          existing_user = build(:user)
          %{access_token: access_token} = author()
          create_user(input: prepare_user(existing_user), access_token: access_token, conn: shared.conn)

          user = build(:user)
          %{access_token: access_token} = author()
          create_response = create_user(input: prepare_user(user), access_token: access_token, conn: shared.conn)
          update_response = update_user(id: ~i(create_response.result.id), input: prepare_user(%{name: existing_user.name, email: existing_user.email}), access_token: access_token, conn: shared.conn)

          refute ~i(update_response.successful)
        end

        it "returns error for anonymous user", validation: true, valid: false do
          user = build(:user)
          %{access_token: access_token} = author()
          create_response = create_user(input: prepare_user(user), access_token: access_token, conn: shared.conn)

          update_response = update_user(id: ~i(create_response.result.id), input: prepare_user(@valid_attrs), conn: shared.conn)

          refute ~i(update_response.successful)
        end

        it "returns error for already deleted user", validation: true, valid: false do
          user = build(:user)
          %{access_token: access_token} = author()
          create_response = create_user(input: prepare_user(user), access_token: access_token, conn: shared.conn)
          delete_user(id: ~i(create_response.result.id), access_token: access_token, conn: shared.conn)

          update_response = update_user(id: ~i(create_response.result.id), input: prepare_user(@valid_attrs), access_token: access_token, conn: shared.conn)

          refute ~i(update_response.successful)
        end

        it "accepts note for revision", audit: true do
          user = build(:user)
          %{access_token: access_token} = author()
          create_response = create_user(input: prepare_user(user), access_token: access_token, conn: shared.conn)

          note = sentence()
          update_response = update_user(id: ~i(create_response.result.id), input: %{note: note}, access_token: access_token, conn: shared.conn)

          expect ~i(update_response.result.note) |> to(eq(note))
        end

        it "increments revision version", audit: true do
          user = build(:user)
          %{access_token: access_token} = author()
          create_response = create_user(input: prepare_user(user), access_token: access_token, conn: shared.conn)
          update_response = update_user(id: ~i(create_response.result.id), input: prepare_user(@valid_attrs), access_token: access_token, conn: shared.conn)

          expect ~i(update_response.result.version) |> to(be(:>, ~i(create_response.result.version)))
        end

        it "sets updated_by to non-nil if context is not empty", audit: true do
          user = build(:user)
          %{access_token: access_token, id: updator_id} = author()
          create_response = create_user(input: prepare_user(user), access_token: access_token, conn: shared.conn)
          update_response = update_user(id: ~i(create_response.result.id), input: prepare_user(@valid_attrs), access_token: access_token, conn: shared.conn)

          expect ~i(update_response.result.updated_by.id) |> to(eq(updator_id))
        end

        it "does not touch created_at", audit: true do
          user = build(:user)
          %{access_token: access_token} = author()
          create_response = create_user(input: prepare_user(user), access_token: access_token, conn: shared.conn)
          update_response = update_user(id: ~i(create_response.result.id), input: prepare_user(@valid_attrs), access_token: access_token, conn: shared.conn)

          expect ~i(update_response.result.created_at) |> to(eq(~i(create_response.result.created_at)))
        end

        it "touches updated_at", audit: true do
          user = build(:user)
          %{access_token: access_token} = author()
          create_response = create_user(input: prepare_user(user), access_token: access_token, conn: shared.conn)
          update_response = update_user(id: ~i(create_response.result.id), input: prepare_user(@valid_attrs), access_token: access_token, conn: shared.conn)

          expect ~i(create_response.result.updated_at) |> to(be_nil())
          expect ~i(update_response.result.updated_at) |> not_to(be_nil())
        end

        [
          user:      [user: false, moderator: true,  admin: true],
          moderator: [user: false, moderator: true,  admin: true],
          admin:     [user: false, moderator: false, admin: true],
        ] |> Enum.each(fn({user_role, cols}) ->
          it "allows #{user_role} to update himself", permission: true, allow: true, self: true do
            user = build(unquote(user_role))
            %{access_token: access_token} = author()
            create_response = create_user(input: prepare_user(user), access_token: access_token, conn: shared.conn)

            name = word()
            access_token = auth(user, shared.conn)
            update_response = update_user(id: ~i(create_response.result.id), input: %{name: name}, access_token: access_token, conn: shared.conn)

            assert ~i(update_response.successful)
          end

          cols |> Enum.each(fn({role, is_allowed}) ->
              it "#{if is_allowed, do: "allows", else: "does not allow"} #{role} to update #{user_role}", permission: true, allow: is_allowed, role: user_role do
                user = build(unquote(user_role))
                %{access_token: access_token} = author()
                create_response = create_user(input: prepare_user(user), access_token: access_token, conn: shared.conn)

                name = word()
                %{access_token: access_token} = unquote(:"author_#{role}")()
                update_response = update_user(id: ~i(create_response.result.id), input: %{name: name}, access_token: access_token, conn: shared.conn)

                if unquote(is_allowed) do
                  assert ~i(update_response.successful)
                else
                  refute ~i(update_response.successful)
                end
              end
          end)
        end)

        [
          user:      [user: false, moderator: true,  admin: true],
          moderator: [user: false, moderator: false, admin: true],
          admin:     [user: false, moderator: false, admin: false],
        ] |> Enum.each(fn({user_role, cols}) ->
          it "allows to change #{user_role} password by himself", permission: true, allow: true, self: true do
            user = build(unquote(user_role))
            %{access_token: access_token} = author()
            create_response = create_user(input: prepare_user(user), access_token: access_token, conn: shared.conn)

            password = word()
            access_token = auth(user, shared.conn)
            update_response = update_user(id: ~i(create_response.result.id), input: %{password: password}, access_token: access_token, conn: shared.conn)

            assert ~i(update_response.successful)
          end

          cols |> Enum.each(fn({role, is_allowed}) ->
              it "#{if is_allowed, do: "allows", else: "does not allow"} #{role} to change #{user_role} password", permission: true, allow: is_allowed, role: role do
                user = build(unquote(user_role))
                %{access_token: access_token} = author()
                create_response = create_user(input: prepare_user(user), access_token: access_token, conn: shared.conn)

                password = word()
                %{access_token: access_token} = unquote(:"author_#{role}")()
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
          user: [
            moderator: [user: false, moderator: true,  admin: true],
            admin:     [user: false, moderator: false, admin: true],
          ],
          moderator: [
            admin:     [user: false, moderator: false, admin: true],
          ]
        ] |> Enum.each(fn({user_role, cols}) ->
          cols |> Enum.each(fn({target_role, col}) ->
            it "does not allow #{user_role} to upgrade his role to #{target_role}", permission: true, allow: false, self: true do
              user = build(unquote(user_role))
              %{access_token: access_token} = author()
              create_response = create_user(input: prepare_user(user), access_token: access_token, conn: shared.conn)

              access_token = auth(user, shared.conn)
              update_response = update_user(id: ~i(create_response.result.id), input: prepare_user(%{role: unquote(target_role)}), access_token: access_token, conn: shared.conn)

              refute ~i(update_response.successful)
            end

            col |> Enum.each(fn({role, is_allowed}) ->
              it "#{if is_allowed, do: "allows", else: "does not allow"} #{role} to upgrade #{user_role} to #{target_role}", permission: true, allow: is_allowed, role: role do
                user = build(unquote(user_role))
                %{access_token: access_token} = author()
                create_response = create_user(input: prepare_user(user), access_token: access_token, conn: shared.conn)

                %{access_token: access_token} = unquote(:"author_#{role}")()
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
          moderator: [
            user:      [user: false, moderator: false, admin: true],
          ],
          admin: [
            user:      [user: false, moderator: false, admin: false],
            moderator: [user: false, moderator: false, admin: false],
          ]
        ] |> Enum.each(fn({user_role, cols}) ->
          cols |> Enum.each(fn({target_role, col}) ->
            it "does not allow #{user_role} to downgrade his role to #{target_role}", permission: true, allow: false, self: true do
              user = build(unquote(user_role))
              %{access_token: access_token} = author()
              create_response = create_user(input: prepare_user(user), access_token: access_token, conn: shared.conn)

              access_token = auth(user, shared.conn)
              update_response = update_user(id: ~i(create_response.result.id), input: prepare_user(%{role: unquote(target_role)}), access_token: access_token, conn: shared.conn)

              refute ~i(update_response.successful)
            end

            col |> Enum.each(fn({role, is_allowed}) ->
              it "#{if is_allowed, do: "allows", else: "does not allow"} #{role} to downgrade #{user_role} to #{target_role}", permission: true, allow: is_allowed, role: user_role do
                user = build(unquote(user_role))
                %{access_token: access_token} = author()
                create_response = create_user(input: prepare_user(user), access_token: access_token, conn: shared.conn)

                %{access_token: access_token} = unquote(:"author_#{role}")()
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

      describe "deleteUser" do
        it "returns success for valid id", validation: true, valid: true do
          user = build(:user)
          %{access_token: access_token} = author()
          create_response = create_user(input: prepare_user(user), access_token: access_token, conn: shared.conn)
          delete_response = delete_user(id: ~i(create_response.result.id), access_token: access_token, conn: shared.conn)

          assert ~i(delete_response.successful)
          expect ~i(delete_response.result) |> to(be_nil())
        end

        it "returns error for unknown id", validation: true, valid: false do
          %{access_token: access_token} = author()
          delete_response = delete_user(id: Ecto.UUID.generate(), access_token: access_token, conn: shared.conn)

          refute ~i(delete_response.successful)
        end

        it "returns success for valid name", validation: true, valid: true do
          user = build(:user)
          %{access_token: access_token} = author()
          create_user(input: prepare_user(user), access_token: access_token, conn: shared.conn)
          delete_response = delete_user(name: user.name, access_token: access_token, conn: shared.conn)

          assert ~i(delete_response.successful)
          expect ~i(delete_response.result) |> to(be_nil())
        end

        it "returns error for unknown name", validation: true, valid: false do
          user = build(:user)
          %{access_token: access_token} = author()
          delete_response = delete_user(name: user.name, access_token: access_token, conn: shared.conn)

          refute ~i(delete_response.successful)
        end

        it "returns success for valid email", validation: true, valid: true do
          user = build(:user)
          %{access_token: access_token} = author()
          create_user(input: prepare_user(user), access_token: access_token, conn: shared.conn)
          delete_response = delete_user(email: user.email, access_token: access_token, conn: shared.conn)

          assert ~i(delete_response.successful)
          expect ~i(delete_response.result) |> to(be_nil())
        end

        it "returns error for unknown email", validation: true, valid: false do
          user = build(:user)
          %{access_token: access_token} = author()
          delete_response = delete_user(email: user.email, access_token: access_token, conn: shared.conn)

          refute ~i(delete_response.successful)
        end

        it "returns success for current user", validation: true, valid: true, self: true do
          user = build(:user)
          %{access_token: access_token} = author()
          create_user(input: prepare_user(user), access_token: access_token, conn: shared.conn)

          access_token = auth(user, shared.conn)
          delete_response = delete_user(access_token: access_token, conn: shared.conn)

          assert ~i(delete_response.successful)
          expect ~i(delete_response.result) |> to(be_nil())
        end

        it "returns error for unknown email", validation: true, valid: false do
          user = build(:user)
          %{access_token: access_token} = author()
          delete_response = delete_user(email: user.email, access_token: access_token, conn: shared.conn)

          refute ~i(delete_response.successful)
        end

        it "returns error for anonymous user", validation: true, valid: false do
          user = build(:user)
          create_response = create_user(input: prepare_user(user), conn: shared.conn)
          delete_response = delete_user(id: ~i(create_response.result.id), conn: shared.conn)

          refute ~i(delete_response.successful)
        end

        it "accepts note for revision", audit: true do
          user = build(:user)
          %{access_token: access_token} = author()
          create_response = create_user(input: prepare_user(user), access_token: access_token, conn: shared.conn)

          note = sentence()
          delete_response = delete_user(id: ~i(create_response.result.id), input: %{note: note}, access_token: access_token, conn: shared.conn)

          assert ~i(delete_response.successful)
        end

        [
          user:      [user: false, moderator: true,   admin: true],
          moderator: [user: false, moderator: false,  admin: true],
          admin:     [user: false, moderator: false,  admin: false],
        ] |> Enum.each(fn({user_role, cols}) ->
          it "allows #{user_role} to delete himself", permission: true, allow: true, self: true do
            user = build(unquote(user_role))
            %{access_token: access_token} = author()
            create_response = create_user(input: prepare_user(user), access_token: access_token, conn: shared.conn)

            access_token = auth(user, shared.conn)
            delete_response = delete_user(id: ~i(create_response.result.id), access_token: access_token, conn: shared.conn)

            assert ~i(delete_response.successful)
          end

          cols |> Enum.each(fn({role, is_allowed}) ->
              it "#{if is_allowed, do: "allows", else: "does not allow"} #{role} to delete #{user_role}", permission: true, allow: is_allowed, role: user_role do
                user = build(unquote(user_role))
                %{access_token: access_token} = author()
                create_response = create_user(input: prepare_user(user), access_token: access_token, conn: shared.conn)

                %{access_token: access_token} = unquote(:"author_#{role}")()
                delete_response = delete_user(id: ~i(create_response.result.id), access_token: access_token, conn: shared.conn)

                if unquote(is_allowed) do
                  assert ~i(delete_response.successful)
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
