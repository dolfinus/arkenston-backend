require 'rails_helper'
require 'base64'

RSpec.describe Auth::Token do
  let(:new_user) { create(:user) }
  let(:new_visitor) { Auth::Visitor.new(id: new_user.id, role: new_user.role) }
  let(:config) { described_class.config }
  let(:expired_config) do
    config.expire = 0
    config
  end

  context 'without error' do
    it 'when token is correct' do
      expect(described_class.verify(new_visitor.access_token).id).to eq(new_visitor.id)
    end
    it 'when token is empty' do
      expect(described_class.verify('').id).to eq(User.anonymous_id)
    end
  end

  context 'with error' do
    it 'when token is corrupted' do
      expect{ described_class.verify(Faker::Lorem.word) }.to raise_error(JWT::DecodeError)
    end
    it 'when token type is wrong' do
      expect{ described_class.verify(new_visitor.refresh_token, :access) }.to raise_error(JWT::VerificationError)
      expect{ described_class.verify(new_visitor.access_token, :refresh) }.to raise_error(JWT::VerificationError)
    end
    it 'when token is expired' do
      allow(described_class).to receive(:config).and_return(expired_config)
      token = new_visitor.access_token
      expect{ described_class.verify(token) }.to raise_error(JWT::ExpiredSignature)
    end
  end
end
