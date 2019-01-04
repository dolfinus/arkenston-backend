class ApplicationMutator < ApplicationFunction
  include GraphQL::Sugar::Mutator
  include Pundit

  def authorize_fields!(instance, fields, policy = nil)
    if fields.is_a?(Array)
      fields.each do |item|
        authorize_action!(instance, item, policy)
      end
    else
      fields.each do |key, _|
        authorize_action!(instance, key, policy)
      end
    end
  end

  def authorize_action!(instance, action, policy = nil)
    if instance.nil?
      authorize instance, "#{action}?".to_sym, policy_class: policy
    else
      authorize instance, "#{action}?".to_sym
    end
  end

  def current_user
    context[:current_user]
  end
end
