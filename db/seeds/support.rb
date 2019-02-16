module Support
  def fill_up_user_locales(user)
    i18n_prefix = "default.users.#{user.name}"
    initial_locale = I18n.locale
    I18n.available_locales.each do |locale|
      I18n.locale = locale
      user.first_name  = I18n.t("#{i18n_prefix}.first_name")
      user.middle_name = I18n.t("#{i18n_prefix}.middle_name")
      user.last_name   = I18n.t("#{i18n_prefix}.last_name")
    end
    I18n.locale = initial_locale
  end
end
