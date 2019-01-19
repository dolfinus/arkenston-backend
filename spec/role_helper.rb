RSpec.shared_examples 'is allowed for setting role of' do |smbd, new_roles|
  context 'is allowed to' do
    context '#update' do # rubocop:disable RSpec/ContextWording
      context 'role' do # rubocop:disable RSpec/ContextWording
        let(:record) { send(smbd) if smbd }
        let(:policy) { described_class.new(current_user, record) }
        let(:allowed_roles) { policy.permitted_values_for_role.map(&:to_sym) }

        old_role = "existing #{smbd}" if smbd
        old_role ||= 'new user'

        context "of #{old_role}" do
          context 'to any of' do # rubocop:disable RSpec/ContextWording
            it new_roles.join(', ') do
              expect(allowed_roles).to include(*new_roles)
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
        let(:record) { send(smbd) if smbd }
        let(:policy) { described_class.new(current_user, record) }
        let(:allowed_roles) { policy.permitted_values_for_role.map(&:to_sym) }

        old_role = "existing #{smbd}" if smbd
        old_role ||= 'new user'

        context "of #{old_role}" do
          context 'to any of' do # rubocop:disable RSpec/ContextWording
            it new_roles.join(', ') do
              expect(allowed_roles).not_to include(*new_roles)
            end
          end
        end
      end
    end
  end
end
