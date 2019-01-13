require_relative '../support'
extend Support

after 'common' do
  User.connection.schema_cache.clear!
  User.reset_column_information

  existing_admin = User.find_by(name: Settings.users.admin.name)
  return if existing_admin.present?

  new_admin = User.new(
    name:           Settings.users.admin.name,
    email:          Settings.users.admin.email,
    role:           Settings.users.admin.role,
    password:       Settings.users.admin.password,
    remember_token: nil
  )
  fill_up_user_locales(new_admin)
  new_admin.save(validate: false)
end
