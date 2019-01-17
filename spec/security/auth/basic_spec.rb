require 'rails_helper'
require 'base64'

RSpec.describe Auth::Basic do
  let(:new_user) { create(:user) }

  context 'without error' do
    it 'when id and password are correct' do
      expect(described_class.verify(id: new_user.id, password: new_user.password).id).to eq(new_user.id)
    end
    it 'when name and password are correct' do
      expect(described_class.verify(name: new_user.name, password: new_user.password).id).to eq(new_user.id)
    end
    it 'when email and password are correct' do
      expect(described_class.verify(email: new_user.email, password: new_user.password).id).to eq(new_user.id)
    end
    it 'when no auth data' do
      expect(described_class.verify({}).id).to eq(User.anonymous_id)
    end
  end

  context 'with error' do
    it 'when id and password are not correct' do
      expect{ described_class.verify(id: Faker::Number.number(5), password: Faker::Lorem.word) }.to raise_error(ActiveRecord::RecordNotFound)
    end
    it 'when name and password are not correct' do
      expect{ described_class.verify(name: Faker::Lorem.word, password: Faker::Lorem.word) }.to raise_error(ActiveRecord::RecordNotFound)
    end
    it 'when email and password are not correct' do
      expect{ described_class.verify(email: Faker::Internet.email, password:  Faker::Lorem.word) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
