module Validators
  class UserTranslationsValidator < ActiveModel::Validator
    def error(record)
      record.errors[:translations] << I18n.t('error.no_translations')
    end

    def validate(record)
      if record.new_record?
        return error(record) if record.first_name.nil? && record.last_name.nil? && record.middle_name.nil?
      else
        return error(record) unless record.translations.where.not(first_name: '', last_name: '', middle_name: '').exists?
      end
    end
  end
end
