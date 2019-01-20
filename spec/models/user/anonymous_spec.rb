require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { create(:user) }
  let(:anonymous) { build(:user, :anonymous) }

  context '.anonymous' do # rubocop:disable RSpec/ContextWording
    context 'without error' do
      it 'when Anonymous is exist' do
        expect(anonymous).not_to be_nil
      end
      it "when Anonymous id is #{User.anonymous_id}" do
        expect(anonymous.id).to eq(User.anonymous_id)
      end
      it "when Anonymous name is #{User.anonymous_name}" do
        expect(anonymous.name).to eq(User.anonymous_name)
      end
      it 'when Anonymous has no email' do
        expect(anonymous.email).to be_blank
      end
      it 'when Anonymous has no password' do
        expect(anonymous.password).to be_blank
      end
      it 'when Anonymous has no remember token' do
        expect(anonymous.remember_token).to be_blank
      end
    end

    context 'with error' do
      it 'when trying to save Anonymous' do
        expect(anonymous).not_to be_valid
      end
    end
  end

  context '#anonymous?' do # rubocop:disable RSpec/ContextWording
    context 'without error' do
      it 'when user is anonymous' do
        expect(User.anonymous).to be_anonymous
      end
    end

    context 'with error' do
      it 'when user is not anonymous' do
        expect(user).not_to be_anonymous
      end
    end
  end
end
