module HasTranslations
  extend ActiveSupport::Concern

  included do
    after_commit :save_translations
  end

  def initialize(params = {})
    unless params.nil?
      super(params.except(:translations))
      update_attributes(params.slice(:translations))
    else
      super
    end
  end

  def translation=(input)
    locale = input[:locale].to_sym
    validator = Validators::TranslationValidator.new
    validator.validate_locale(self, locale)
    validator.validate_attrs(self, input)

    Globalize.with_locale(locale) do
      translated_attribute_names.each do |attr|
        value = ''
        value = input[attr] if input[attr].present?

        send("#{attr}=", value)
      end
    end
  end

  def translations=(input)
    input.each do |item|
      self.translation = item
    end
  end

  def update_attributes(params)
    self.attributes = params.except(:translations)
    self.translations = params[:translations] if params[:translations].present?
  end

  def save_translations
    translations.each do |item|
      item.user_id = id if item.new_record?
      item.save!
    end
  end

  def remove_translation(locale)
    translation = translation_for(locale)
    raise ActiveRecord::RecordNotFound.new('', "#{self.class.name}::Translation", locale, locale) if translation.new_record?

    translation_for(locale).destroy!
  end

  module ClassMethods
    def translate_attrs(*fields, **options)
      has_versions = respond_to?(:translation_versioning_options)
      validates_with Validators::TranslationValidator

      if has_versions
        translates(*fields, **options, **translation_versioning_options)
        "#{self}::Translation".constantize.class_eval { acts_as_paranoid }
      else
        translates(*fields, **options)
      end
    end
  end
end
