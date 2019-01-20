require 'rails_helper'
require 'policy_helper'

RSpec.describe UserPolicy do
  include_context 'policy'

  public_attrs = %i[name email role translations versions]
  private_attrs = %i[remember_token]
  prohibited_attrs = %i[password]

  context 'when current is' do
    %i[anonymous].each do |curr|
      context ":#{curr}" do
        let(:current_user) { send(curr) }

        include_examples 'is allowed for', '#access', public_attrs
        include_examples 'is not allowed for', '#access', private_attrs + prohibited_attrs
      end
    end

    %i[user moderator admin].each do |curr|
      context ":#{curr}" do
        let(:current_user) { send(curr) }

        include_examples 'is allowed for', '#access', public_attrs
        include_examples 'is not allowed for', '#access', prohibited_attrs

        context 'when record is not current' do
          include_examples 'is not allowed for', '#access', private_attrs
        end

        context 'when record is current' do
          let(:record) { current_user }

          include_examples 'is allowed for', '#access', private_attrs
        end
      end
    end
  end
end
