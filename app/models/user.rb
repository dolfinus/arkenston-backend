class User < ApplicationRecord
  include Clearance::User
  include HasRole
  has_paper_trail skip: [:encrypted_password, :remember_token, :confirmation_token, :created_at, :updated_at]

  validates_format_of :name, with: /^[a-zA-Z0-9_\.]*$/, multiline: true
  translates :first_name, :middle_name, :last_name, fallbacks_for_empty_translations: true, versioning: :paper_trail

  def to_param
    name
  end

  def full_name
    [first_name, middle_name, last_name].join ' '
  end

  def jwt
    Auth::Token.generate(self)
  end

  def anonymous?
    self.name == User.anonymous_name
  end

  def self.anonymous_name
    'anonymous'
  end

  def self.anonymous
    find_by_name(User.anonymous_name)
  end
end
