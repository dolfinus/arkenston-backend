module HasTranslations
  extend ActiveSupport::Concern

  included do
    after_commit :save_translations
  end

  def initialize(params = {})
    unless params.nil?
      super(params.except(:translations))
      update_attributes(params)
    else
      super
    end
  end

  def translation=(input)
    Globalize.with_locale(input[:locale]) do
      translated_attribute_names.each do |attr|
        value = input[attr].nil? ? '' : input[attr]
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
    self.translations = params[:translations] unless params[:translations].nil?
  end

  def save_translations
    translations.each do |item|
      item.user_id = id if item.new_record?
      item.save!
    end
  end

  def remove_translation(locale)
    translation = translation_for(locale)
    raise ActiveRecord::RecordNotFound.new('', User::Translation.to_s, locale, locale) if translation.new_record?

    translation_for(locale).destroy!
  end

  module ClassMethods
    def translate_attrs(*fields, **options)
      has_versions = respond_to?(:translation_versioning_options)

      if has_versions
        translates(*fields, **options, **translation_versioning_options)
        "#{self}::Translation".constantize.class_eval { acts_as_paranoid }
      else
        translates(*fields, **options)
      end
    end
  end
end
