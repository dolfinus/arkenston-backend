require 'rails_helper'

describe Schema do
  it 'dumped schema should be up to date' do
    actual_schema = GraphQL::Schema::Printer.print_schema(described_class)
    dumped_schema = File.read(Rails.root.join('app', 'graphql', 'schema.graphql'))

    expect(actual_schema).to eq(dumped_schema), 'GraphQL Schema is out of date. Please run rake graphql:dump'
  end
end
