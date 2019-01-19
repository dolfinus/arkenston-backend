require 'rails_helper'
require 'policy_helper'

RSpec.describe UserPolicy do
  include_context 'policy'
  let(:policy) { described_class.new(current_user, record) }

  context 'when current is' do
    %i[anonymous].each do |curr|
      context ":#{curr}" do
        let(:current_user) { send(curr) }

        include_examples 'is not allowed for', '#destroy'
      end
    end

    %i[admin].each do |curr|
      context ":#{curr}" do
        let(:current_user) { send(curr) }

        include_examples 'is allowed for', '#destroy'
      end
    end

    %i[user moderator].each do |curr|
      context ":#{curr}" do
        let(:current_user) { send(curr) }

        context 'when record is not current' do
          include_examples 'is not allowed for', '#destroy'
        end

        context 'when record is current' do
          let(:record) { current_user }

          include_examples 'is allowed for', '#destroy'
        end
      end
    end
  end
end
