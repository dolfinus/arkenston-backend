module ChecksPolicy
  extend ActiveSupport::Concern

  included do
    include Pundit
  end

  def authorized_attrs_list(policy, action)
    method_name = "permitted_attributes_for_#{action}"
    method_name = 'permitted_attributes' unless policy.respond_to?(method_name)

    policy.send(method_name)
  end

  def find_policy(record, policy_class = nil)
    current_user ||= record.current_user unless record.nil?

    policy_class ? policy_class.new(current_user, record) : Pundit.policy(current_user, record)
  end

  def authorize_params!(record, params, action = :access, policy_class = nil)
    policy = find_policy(record, policy_class)
    authorize_action! record, action, policy

    real_params = authorized_attrs_list(policy, action)
    params = params.keys unless params.is_a?(Array)

    non_acceptable = params.reject { |item| real_params.include?(item) }

    raise Pundit::NotAuthorizedError.new(record: record, policy: policy, query: "#{action} #{non_acceptable.first} of") unless non_acceptable.empty?
  end

  def authorize_param!(record, param, action = :access, policy_class = nil)
    authorize_params!(record, [param], action, policy_class)
  end

  def authorize_param_with_context!(record, param, context = {}, action = :access, policy_class = nil)
    record.current_user = context[:current_user] unless current_user
    authorize_param!(record, param, action, policy_class)
  end

  def field_policy_check(field, obj, _args, ctx)
    authorize_param_with_context!(obj, field, ctx)
    obj.send(field)
  end

  def authorize_action!(record, action, policy_class = nil)
    return authorize record, "#{action}?", policy_class: policy_class if record.nil?

    authorize record, "#{action}?"
  end
end
