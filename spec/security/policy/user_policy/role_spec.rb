require 'rails_helper'
require 'role_helper'

RSpec.describe UserPolicy do
  include_context 'policy'

  context 'when current is' do
    context ':user' do # rubocop:disable RSpec/ContextWording
      let(:current_user) { user }

      [nil, :user].each do |smbd|
        include_examples 'is allowed for setting role of', smbd, %i[user]
      end

      %i[moderator admin].each do |smbd|
        include_examples 'is not allowed for setting role of', smbd, %i[user moderator admin]
      end
    end

    context ':moderator' do # rubocop:disable RSpec/ContextWording
      let(:current_user) { moderator }

      [nil, :user, :moderator].each do |smbd|
        include_examples 'is allowed for setting role of', smbd, %i[user moderator]
      end

      %i[admin].each do |smbd|
        include_examples 'is not allowed for setting role of', smbd, %i[user moderator admin]
      end
    end

    context ':admin' do # rubocop:disable RSpec/ContextWording
      let(:current_user) { admin }

      [nil, :user, :moderator, :admin].each do |smbd|
        include_examples 'is allowed for setting role of', smbd, %i[user moderator admin]
      end
    end
  end
end
