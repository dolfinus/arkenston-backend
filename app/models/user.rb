class User < ApplicationRecord
  include Clearance::User
  include HasRole
  has_paper_trail

  validates_format_of :name, with: /^[a-zA-Z0-9_\.]*$/, multiline: true
  translates :first_name, :middle_name, :last_name, fallbacks_for_empty_translations: true, versioning: :paper_trail

  def to_param
    name
  end

  def full_name
    [first_name, middle_name, last_name].join ' '
  end
end
