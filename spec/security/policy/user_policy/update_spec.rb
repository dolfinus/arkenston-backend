require 'rails_helper'
require 'policy_helper'

RSpec.describe UserPolicy do
  include_context 'policy'

  public_attrs = %i[name email role translations]
  private_attrs = %i[password]
  prohibited_attrs = %i[remember_token]

  context 'when current is' do
    %i[anonymous].each do |curr|
      context ":#{curr}" do
        let(:current_user) { send(curr) }

        include_examples 'is not allowed for', '#update'
      end
    end

    %i[user].each do |curr|
      context ":#{curr}" do
        let(:current_user) { send(curr) }

        context 'when record is not current' do
          include_examples 'is not allowed for', '#update'
        end

        context 'when record is current' do
          let(:record) { current_user }

          include_examples 'is allowed for', '#update', public_attrs
          include_examples 'is allowed for', '#update', private_attrs
          include_examples 'is not allowed for', '#update', prohibited_attrs
        end
      end
    end

    %i[moderator admin].each do |curr|
      context ":#{curr}" do
        let(:current_user) { send(curr) }

        include_examples 'is allowed for', '#update', public_attrs
        include_examples 'is not allowed for', '#update', prohibited_attrs

        context 'when record is not current' do
          include_examples 'is not allowed for', '#update', private_attrs
        end

        context 'when record is current' do
          let(:record) { current_user }

          include_examples 'is allowed for', '#update', private_attrs
        end
      end
    end
  end
end
