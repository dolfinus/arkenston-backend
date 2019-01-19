RSpec.shared_context 'policy' do # rubocop:disable RSpec/ContextWording
  let(:admin) { build(:visitor, :admin) }
  let(:moderator) { build(:visitor, :moderator) }
  let(:anonymous) { build(:visitor, :anonymous) }
  let(:user) { build(:visitor) }
  let(:record) { nil }
  let(:policy) { described_class.new(current_user, record) }
end

RSpec.shared_examples 'is allowed for' do |method, attrs|
  context 'is allowed to' do
    unless attrs
      it method do
        expect(policy.send("#{method.to_s.delete('#').delete('.')}?")).to be_truthy
      end
    end
    attrs = [] if attrs.blank?
    attrs = [attrs] unless attrs.is_a?(Array)

    context method do
      attrs.each do |attr|
        it attr.to_s.delete('#') do
          expect(attributes).to include(attr.to_s.delete('#').delete('=').to_sym)
        end
      end
    end
  end
end

RSpec.shared_examples 'is not allowed for' do |method, attrs|
  context 'is not allowed to' do
    unless attrs
      it method do
        expect(policy.send("#{method.to_s.delete('#').delete('.')}?")).to be_falsey
      end
    end
    attrs = [] if attrs.blank?
    attrs = [attrs] unless attrs.is_a?(Array)

    context method do
      attrs.each do |attr|
        it attr.to_s.delete('#') do
          expect(attributes).not_to include(attr.to_s.delete('#').delete('=').to_sym)
        end
      end
    end
  end
end
