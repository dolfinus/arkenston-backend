require 'rails_helper'
require 'policy_helper'

describe UserPolicy do
  include_context 'policy'

  public_attrs = %i[name email role translations password]

  context 'when current is' do
    %i[anonymous moderator admin].each do |curr|
      context ":#{curr}" do
        let(:current_user) { send(curr) }

        include_examples 'is allowed for', '.create'
        include_examples 'is allowed for', '.create', public_attrs
      end
    end

    %i[user].each do |curr|
      context ":#{curr}" do
        let(:current_user) { send(curr) }

        include_examples 'is not allowed for', '.create'
      end
    end
  end
end
