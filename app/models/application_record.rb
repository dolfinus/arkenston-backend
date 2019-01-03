require 'active_record/diff'

class ApplicationRecord < ActiveRecord::Base
  include ActiveRecord::Diff
  include ActiveModel::Validations
  self.abstract_class = true
end
