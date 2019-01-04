require 'rails_helper'

RSpec.describe User, type: :model do
  context 'is valid' do # rubocop:disable RSpec/ContextWording
    it 'when attributes are valid' do
      expect(create(:user)).to be_valid
    end
  end

  context 'is not valid' do # rubocop:disable RSpec/ContextWording
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
      expect { build(:user, role: Faker::Lorem.word.to_sym) }.to raise_error.with_message(/is not a valid role/)
    end
    it 'with name already used' do
      existing_user = create(:user)
      double_user = build(:user, name: existing_user.name)
      expect(double_user).not_to be_valid
    end
    it 'with email already used' do
      existing_user = create(:user)
      double_user = build(:user, email: existing_user.email)
      expect(double_user).not_to be_valid
    end
  end
end
