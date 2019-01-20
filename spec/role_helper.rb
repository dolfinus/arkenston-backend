RSpec.shared_examples 'is allowed for setting role of' do |smbd, new_roles|
  context 'is allowed to' do
    context '#update' do # rubocop:disable RSpec/ContextWording
      context 'role' do # rubocop:disable RSpec/ContextWording
        let(:record) { send(smbd) }

        new_roles = [new_roles] unless new_roles.is_a?(Array)

        context "of existing #{smbd}" do
          context 'to any of' do # rubocop:disable RSpec/ContextWording
            it new_roles.join(', ') do
              record.current_user = current_user
              expect(record.assignable_roles).to include(*new_roles)
            end
          end
        end
      end
    end
  end
end

RSpec.shared_examples 'is not allowed for setting role of' do |smbd, new_roles|
  context 'is not allowed to' do
    context '#update' do # rubocop:disable RSpec/ContextWording
      context 'role' do # rubocop:disable RSpec/ContextWording
        let(:record) { send(smbd) }

        new_roles = [new_roles] unless new_roles.is_a?(Array)

        context "of existing #{smbd}" do
          context 'to any of' do # rubocop:disable RSpec/ContextWording
            it new_roles.join(', ') do
              record.current_user = current_user
              expect(record.assignable_roles).not_to include(*new_roles)
            end
          end
        end
      end
    end
  end
end
