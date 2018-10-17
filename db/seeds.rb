def seed
  add_admin
end

def add_admin
  User.connection.schema_cache.clear!
  User.reset_column_information

  existing_admin = User.find_by(email: 'admin@example.com')

  unless existing_admin.present?
    new_admin = User.new(
      name:           'admin',
      role:           :admin,
      first_name:     'Simple',
      middle_name:    'Admin',
      last_name:      'User',
      email:          'admin@example.com',
      password:       '12345678',
      remember_token: '#{Clearance::Token.new}'
    )
    new_admin.save!
  end
end

seed