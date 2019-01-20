require 'rails_helper'

RSpec.describe User, type: :model do
  let(:existing_user) { create(:user) }
  let(:unknown_locale) { build(:user_translation, :unknown_locale) }

  context '.new' do # rubocop:disable RSpec/ContextWording
    context 'is valid' do
      it 'when attributes are correct' do
        expect(build(:user)).to be_valid
      end
    end

    context 'is not valid' do
      it 'without name' do
        expect(build(:user, name: nil)).not_to be_valid
      end
      it 'without email' do
        expect(build(:user, email: nil)).not_to be_valid
      end
      it 'without password' do
        expect(build(:user, password: nil)).not_to be_valid
      end
      it 'with name contains non-latin symbols' do
        expect(build(:user, name: 'Тест')).not_to be_valid
      end
      it 'with wrong formated email' do
        expect(build(:user, email: Faker::Lorem.word)).not_to be_valid
      end
      it 'with unknown role' do
        expect(build(:user, role: Faker::Lorem.word)).not_to be_valid
      end
      it 'without any translation' do
        expect(build(:user, first_name: '', last_name: '', middle_name: '')).not_to be_valid
      end
      it 'with name already used' do
        double_user = build(:user, name: existing_user.name)
        expect(double_user).not_to be_valid
      end
      it 'with email already used' do
        double_user = build(:user, email: existing_user.email)
        expect(double_user).not_to be_valid
      end
    end
  end
end
