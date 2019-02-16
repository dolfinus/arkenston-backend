class Types::PageInfoType < GraphQL::Types::Relay::PageInfo
  default_relay true
  description 'Information about pagination in a connection.'
  field :has_next_page, Boolean, null: false,
    description: 'When paginating forwards, are there more items?',
    camelize: false

  field :has_previous_page, Boolean, null: false,
    description: 'When paginating backwards, are there more items?',
    camelize: false

  field :start_cursor, String, null: true,
    description: 'When paginating backwards, the cursor to continue.',
    camelize: false

  field :end_cursor, String, null: true,
    description: 'When paginating forwards, the cursor to continue.',
    camelize: false
end
