require 'active_record/diff'

class ApplicationRecord < ActiveRecord::Base
  include ActiveRecord::Diff
  include ActiveModel::Validations
  
  attr_accessor :current_user
  self.abstract_class = true

  def initialize(params = {})
    super(params)
    params.each { |key, value| send "#{key}=", value } unless params.nil?
  end
end
