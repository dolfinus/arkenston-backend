require 'rails_helper'

RSpec.describe User, type: :model do
  context '#anonymous' do # rubocop:disable RSpec/ContextWording
    context 'without error' do
      it 'when Anonymous is exist' do
        expect(User.anonymous).not_to be_nil
      end
      it 'when Anonymous id is -1' do
        expect(User.anonymous_id).to eq(-1)
      end
      it 'when Anonymous name is "anonymous"' do
        expect(User.anonymous_name).to eq('anonymous')
      end
      it 'when Anonymous has no email and password' do
        expect(User.anonymous).not_to be_valid
      end
    end
  end
end
