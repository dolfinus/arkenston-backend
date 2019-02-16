require 'rails_helper'

describe Schema do
  it 'dumped schema is up to date' do
    actual_schema = GraphQL::Schema::Printer.print_schema(described_class)
    dumped_schema = File.read(Rails.root.join(Settings.graphql.schema.dsl))

    expect(actual_schema).to eq(dumped_schema), 'GraphQL Schema is out of date. Please run rake graphql:dump'
  end
end
