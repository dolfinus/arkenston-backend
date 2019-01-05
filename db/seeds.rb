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
      email:          '',
      password:       '',
      remember_token: ''
    )
    fill_up_user_locales(new_anonymous)
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
      email:          'admin@example.com',
      password:       '12345678',
      remember_token: '#{Clearance::Token.new}'
    )
    fill_up_user_locales(new_admin)
    new_admin.save
  end
end

def fill_up_user_locales(user)
  i18n_prefix = "default.users.#{user.name}"

  I18n.available_locales.each do |locale|
    I18n.locale = locale
    user.first_name  = I18n.t("#{i18n_prefix}.first_name")
    user.middle_name = I18n.t("#{i18n_prefix}.middle_name")
    user.last_name   = I18n.t("#{i18n_prefix}.last_name")
  end
  I18n.locale = I18n.default_locale
end

seed
