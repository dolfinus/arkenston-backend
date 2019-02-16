require 'rails_helper'
require 'role_helper'

describe UserPolicy do
  include_context 'policy'
  all_roles = User.all_roles

  context 'when current is' do
    context ':user' do # rubocop:disable RSpec/ContextWording
      let(:current_user) { user }

      %i[user].each do |smbd|
        lower_or_same = %w[user]
        include_examples 'is allowed for setting role of', smbd, lower_or_same
      end

      %i[moderator admin].each do |smbd|
        current_roles = [smbd.to_s]
        other_roles = all_roles - current_roles
        include_examples 'is allowed for setting role of', smbd, current_roles
        include_examples 'is not allowed for setting role of', smbd, other_roles
      end
    end

    context ':moderator' do # rubocop:disable RSpec/ContextWording
      let(:current_user) { moderator }

      %i[user moderator].each do |smbd|
        lower_or_same = %w[user moderator]
        include_examples 'is allowed for setting role of', smbd, lower_or_same
      end

      %i[admin].each do |smbd|
        current_roles = [smbd.to_s]
        other_roles = all_roles - current_roles
        include_examples 'is allowed for setting role of', smbd, current_roles
        include_examples 'is not allowed for setting role of', smbd, other_roles
      end
    end

    context ':admin' do # rubocop:disable RSpec/ContextWording
      let(:current_user) { admin }

      %i[user moderator admin].each do |smbd|
        lower_or_same = all_roles
        include_examples 'is allowed for setting role of', smbd, lower_or_same
      end
    end
  end
end
