require 'rails_helper'

RSpec.describe User, type: :model do
  context '#anonymous' do # rubocop:disable RSpec/ContextWording
    context 'without error' do
      it 'when Anonymous is exist' do
        expect(User.anonymous).not_to be_nil
      end
      it 'when Anonymous name is "anonymous"' do
        expect(User.anonymous_name).to eq('anonymous')
      end
    end

    context 'with error' do
      it 'when Anonymous has no email and password' do
        expect(User.anonymous).not_to be_valid
      end
    end
  end
end
