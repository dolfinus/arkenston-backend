require_relative 'support'
extend Support

# Add anonymous
User.connection.schema_cache.clear!
User.reset_column_information

existing_anonymous = User.find_by(id: User.anonymous_id)
return if existing_anonymous.present?

new_anonymous = User.new(
  id:             User.anonymous_id,
  name:           User.anonymous_name,
  role:           User.anonymous_role,
  email:          '',
  password:       '',
  remember_token: nil
)
fill_up_user_locales(new_anonymous)
new_anonymous.save(validate: false)
