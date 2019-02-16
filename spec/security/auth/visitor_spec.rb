require 'rails_helper'

describe Auth::Visitor do
  let(:real_user) { create(:user) }
  let(:fake_visitor) { build(:visitor) }
  let(:real_visitor) { build(:visitor, id: real_user.id, role: real_user.role) }
  let(:anonymous_visitor) { build(:visitor, :anonymous) }

  context '.access_token' do # rubocop:disable RSpec/ContextWording
    context 'without error' do
      it 'when getting token of real user' do
        expect(real_visitor).to respond_to(:access_token)
      end
    end

    context 'with error' do
      it 'when getting token of anonymous' do
        expect(anonymous_visitor.access_token).to be_nil
      end
    end
  end

  context '.refresh_token' do # rubocop:disable RSpec/ContextWording
    context 'without error' do
      it 'when getting token of real user' do
        expect(real_visitor).to respond_to(:refresh_token)
      end
    end

    context 'with error' do
      it 'when getting token of anonymous' do
        expect(anonymous_visitor.refresh_token).to be_nil
      end
    end
  end

  context '#method_missing' do # rubocop:disable RSpec/ContextWording
    context 'without error' do
      it 'when proxying method to user class' do
        expect(real_visitor.name).to       eq(real_user.name)
        expect(real_visitor.email).to      eq(real_user.email)
        expect(real_visitor.first_name).to eq(real_user.first_name)
        expect(real_visitor.last_name).to  eq(real_user.last_name)
      end
    end

    context 'with error' do
      it 'when proxy user does not exist' do
        expect{ fake_visitor.name }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
