module Validators
  class TranslationValidator < ActiveModel::Validator
    def missing_translations(record)
      record.errors[:translations] << I18n.t('error.record.translations.missing')
    end

    def invalid_translations(record)
      record.errors[:translations] << I18n.t('error.record.translations.invalid')
      raise ActiveRecord::RecordInvalid.new(record) # rubocop:disable Style/RaiseArgs
    end

    def validate_locale(record, locale)
      invalid_translations(record) unless I18n.available_locales.include?(locale)
    end

    def validate_attrs(record, input)
      unknown_fields = input.except(:locale).reject { |attr| record.translated_attribute_names.include?(attr) }
      invalid_translations(record) unless unknown_fields.empty?
    end

    def validate(record)
      valid = false
      if record.new_record?
        record.translated_attribute_names.each do |attr|
          valid = true if record[attr].present?
        end
      else
        all_empty = {}
        record.translated_attribute_names.each do |attr|
          all_empty[attr] = ''
        end
        valid = true if record.translations.where.not(all_empty).exists?
      end
      return missing_translations(record) unless valid
    end
  end
end
