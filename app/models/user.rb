class User < ApplicationRecord
  def self.skipped_version_attrs
    %i[encrypted_password remember_token confirmation_token created_at updated_at]
  end

  include Clearance::User
  include HasRole
  include HasTranslations
  include HasVersions

  validates :name, format: /[a-zA-Z0-9_\.]+/, uniqueness: true
  validates_with Validators::UserTranslationsValidator
  translates :first_name, :middle_name, :last_name, fallbacks_for_empty_translations: true, **translation_versioning_options

  def to_param
    name
  end

  def full_name
    [first_name, middle_name, last_name].join ' '
  end

  def jwt
    Auth::Token.generate(self) unless anonymous?
  end

  def anonymous?
    name == User.anonymous_name
  end

  def self.anonymous_name
    'anonymous'
  end

  def self.anonymous
    find_by(name: User.anonymous_name)
  end
end
