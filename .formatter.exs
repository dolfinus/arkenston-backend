locals_without_parens = [
  paginated: 1,
  paginated_node: 1,
  audited_object: 2,
  assoc: 1,
  assoc: 2,
  connection: 1,
  connect_with: 2,
  connect_with: 3,
  connect_with: 4,
  connect_with: 5,
  connect_with_audited: 2,
  connect_with_audited: 3,
  connect_with_audited: 4,
  connect_with_audited: 5,
  connect_with_field: 3,
  connect_with_field: 4,
  connect_with_field: 5,
  connect_with_field: 6,
  connect_with_field_audited: 3,
  connect_with_field_audited: 4,
  connect_with_field_audited: 5,
  connect_with_field_audited: 6,
  translate: 1,
  translate: 2,
  audited_translated_object: 1,
  audited_translated_object: 2,
  audited_translated_object: 3,
  audited_translated_object: 4,
  object: 1,
  payload_object: 2
]

[
  inputs: ["{mix,.formatter}.exs", "{config,lib,priv}/**/*.{ex,exs}"],
  import_deps: [
    :ecto,
    :ecto_sql,
    :phoenix,
    :phoenix_ecto,
    :absinthe,
    :absinthe_error_payload,
    :absinthe_relay,
    :dataloader,
    :trans,
    :ecto_enum,
    :inflex,
    :linguist,
    :ex_cldr,
    :guardian,
    :guardian_phoenix,
    :indifferent
  ],
  locals_without_parens: locals_without_parens,
  export: [
    locals_without_parens: locals_without_parens
  ]
]
