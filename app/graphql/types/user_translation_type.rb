Types::UserTranslationType = GraphQL::ObjectType.define do
  model_class User::Translation, 'UserTranslation'

  attributes :first_name, :middle_name, :last_name, :locale, :created_at, :updated_at
  attribute :full_name, types.String, resolve: ->(obj, _, _) { [obj.first_name, obj.middle_name, obj.last_name].join(' ').strip }
  relationships :versions
end
