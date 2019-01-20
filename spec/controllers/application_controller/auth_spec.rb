require 'rails_helper'

RSpec.describe ApplicationController do
  let(:user) { create(:user) }
  let(:visitor) { build(:visitor, id: user.id, role: user.role) }

  before do
    class ApplicationController
      def index
        render json: { data: { id: current_user.id } }, status: 200
      end
    end

    Rails.application.routes.draw do
      get '/index', to: 'application#index' # rubocop:disable Rails/HttpPositionalArguments
    end
  end

  after do
    Rails.application.reload_routes!
  end

  context 'without error' do
    context 'when Authorization header' do
      it 'is Bearer with access token' do
        @request.headers['Authorization'] = "Bearer #{visitor.access_token}" # rubocop:disable RSpec/InstanceVariable
        get :index
        expect(response.status).to eq(200)
        expect(JSON.parse(response.body)['data']['id']).to eq(visitor.id)
      end
      it 'is empty' do
        @request.headers['Authorization'] = '' # rubocop:disable RSpec/InstanceVariable
        get :index
        expect(response.status).to eq(200)
        expect(JSON.parse(response.body)['data']['id']).to eq(Auth::Visitor.anonymous.id)
      end
      it 'is missing' do
        get :index
        expect(response.status).to eq(200)
        expect(JSON.parse(response.body)['data']['id']).to eq(Auth::Visitor.anonymous.id)
      end
    end
  end

  context 'with error' do
    context 'when Authorization header' do
      it 'is Basic auth' do
        @request.headers['Authorization'] = "Basic #{Faker::Lorem.word}" # rubocop:disable RSpec/InstanceVariable
        get :index
        expect(response.status).to eq(401)
      end
      it 'is Bearer with refresh token' do
        @request.headers['Authorization'] = "Bearer #{visitor.refresh_token}" # rubocop:disable RSpec/InstanceVariable
        get :index
        expect(response.status).to eq(401)
      end
      it 'is Bearer with remember token' do
        @request.headers['Authorization'] = "Bearer #{visitor.remember_token}" # rubocop:disable RSpec/InstanceVariable
        get :index
        expect(response.status).to eq(401)
      end
    end
  end
end
