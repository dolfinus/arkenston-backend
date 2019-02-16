require 'rails_helper'

describe ApplicationController do
  before do
    class ApplicationController
      def raise_record_missing
        raise ActiveRecord::RecordNotFound
      end

      def raise_record_invalid
        raise ActiveRecord::RecordInvalid
      end

      def raise_policy_prohibited
        raise Pundit::NotAuthorizedError
      end

      def raise_token_corrupted
        raise JWT::DecodeError
      end

      def raise_token_invalid
        raise JWT::VerificationError
      end

      def raise_token_expired
        raise JWT::ExpiredSignature
      end

      def raise_auth_method_prohibited
        raise Auth::Error::NotAuthorized
      end
    end

    Rails.application.routes.draw do
      get '/record_missing', to: 'application#raise_record_missing' # rubocop:disable Rails/HttpPositionalArguments
      get '/record_invalid', to: 'application#raise_record_invalid' # rubocop:disable Rails/HttpPositionalArguments
      get '/policy_prohibited', to: 'application#raise_policy_prohibited' # rubocop:disable Rails/HttpPositionalArguments
      get '/token_corrupted', to: 'application#raise_token_corrupted' # rubocop:disable Rails/HttpPositionalArguments
      get '/token_invalid', to: 'application#raise_token_invalid' # rubocop:disable Rails/HttpPositionalArguments
      get '/token_expired', to: 'application#raise_token_expired' # rubocop:disable Rails/HttpPositionalArguments
      get '/auth_method_prohibited', to: 'application#raise_auth_method_prohibited' # rubocop:disable Rails/HttpPositionalArguments
    end
  end

  after do
    Rails.application.reload_routes!
  end

  context 'with error' do
    it 'when record is missing' do
      get :raise_record_missing
      expect(response.status).to eq(404)
      expect(JSON.parse(response.body)['errors'][0]['message']).to match(/not found/)
    end
    it 'when record is invalid' do
      get :raise_record_invalid
      expect(response.status).to eq(404)
      expect(JSON.parse(response.body)['errors'][0]['message']).to match(/not valid/)
    end
    it 'when prohibited by policy' do
      get :raise_policy_prohibited
      expect(response.status).to eq(403)
      expect(JSON.parse(response.body)['errors'][0]['message']).to match(/Insufficiend privileges/)
    end
    it 'when token corrupted' do
      get :raise_token_corrupted
      expect(response.status).to eq(401)
      expect(JSON.parse(response.body)['errors'][0]['message']).to match(/token is invalid/)
    end
    it 'when token invalid' do
      get :raise_token_invalid
      expect(response.status).to eq(401)
      expect(JSON.parse(response.body)['errors'][0]['message']).to match(/token is invalid/)
    end
    it 'when token expired' do
      get :raise_token_expired
      expect(response.status).to eq(401)
      expect(JSON.parse(response.body)['errors'][0]['message']).to match(/token was expired/)
    end
    it 'when auth method prohibited' do
      get :raise_auth_method_prohibited
      expect(response.status).to eq(401)
      expect(JSON.parse(response.body)['errors'][0]['message']).to match(/is not allowed/)
    end
  end
end
