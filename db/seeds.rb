def seed
  add_anonymous
  add_admin
end

def add_anonymous
  User.connection.schema_cache.clear!
  User.reset_column_information

  existing_anonymous = User.find_by(name: 'anonymous')

  unless existing_anonymous.present?
    new_anonymous = User.new(
      name:           'anonymous',
      role:           :user,
      first_name:     '',
      middle_name:    '',
      last_name:      '',
      email:          '',
      password:       '',
      remember_token: ''
    )
    new_anonymous.save(validate: false)
  end
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