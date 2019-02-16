class User < ApplicationRecord
  def self.skipped_version_attrs
    %i[encrypted_password remember_token confirmation_token created_at updated_at]
  end

  include Clearance::User
  include HasRole
  include HasTranslations
  include HasVersions
  include ChecksPolicy

  validates :name, format: Regexp.new(Settings.users.name.format), uniqueness: true
  translate_attrs :first_name, :middle_name, :last_name, fallbacks_for_empty_translations: true

  def anonymous?
    id == User.anonymous_id
  end

  def self.anonymous
    find(User.anonymous_id)
  end

  def self.anonymous_name
    Settings.users.anonymous.name
  end

  def self.anonymous_id
    Settings.users.anonymous.id
  end

  def self.uniq_fields
    %i[id name email]
  end

  def self.filtrate_uniq_fields(input)
    input.select { |item| item.in?(User.uniq_fields) }
  end

  def self.find_uniq(input)
    uniq_fields.each do |attr|
      return find_by!("#{attr}": input[attr]) if input[attr]
    end
    nil
  end
end
