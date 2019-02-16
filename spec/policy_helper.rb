RSpec.shared_context 'policy' do # rubocop:disable RSpec/ContextWording
  include ChecksPolicy
  let(:anonymous) { build(:visitor, :anonymous) }

  let(:existing_user) { create(:user) }
  let(:existing_moderator) { create(:user, :moderator) }
  let(:existing_admin) { create(:user, :admin) }

  let(:admin) { build(:visitor, :admin, id: existing_admin.id) }
  let(:moderator) { build(:visitor, :moderator, id: existing_moderator.id) }
  let(:user) { build(:visitor, id: existing_user.id) }
  let(:record) { nil }
  let(:context) { { current_user: current_user } }
end

RSpec.shared_examples 'is allowed for' do |method, attrs|
  context 'is allowed to' do
    action = method.to_s.delete('#').delete('.').delete('?')

    unless attrs
      it method do
        expect { authorize_action!(record, action, described_class) }.not_to raise_error(Pundit::NotAuthorizedError)
      end
    end
    attrs = [] if attrs.blank?
    attrs = [attrs] unless attrs.is_a?(Array)
    attributes = attrs.each { |attr| attr.to_s.delete('#').delete('=') }

    context method do
      attributes.each do |attr|
        it attr do
          expect { authorize_param_with_context!(record, attr, context, action, described_class) }.not_to raise_error(Pundit::NotAuthorizedError)
        end
      end
    end
  end
end

RSpec.shared_examples 'is not allowed for' do |method, attrs|
  context 'is not allowed to' do
    action = method.to_s.delete('#').delete('.').delete('?')

    unless attrs
      it method do
        expect { authorize_action!(record, action, described_class) }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
    attrs = [] if attrs.blank?
    attrs = [attrs] unless attrs.is_a?(Array)
    attributes = attrs.each { |attr| attr.to_s.delete('#').delete('=') }

    context method do
      attributes.each do |attr|
        it attr do
          expect { authorize_param_with_context!(record, attr, context, action, described_class) }.to raise_error(Pundit::NotAuthorizedError)
        end
      end
    end
  end
end
