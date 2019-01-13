module ErrorHandler
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordNotFound, with: :record_missing
    rescue_from ActiveRecord::RecordInvalid, with: :record_invalid
    rescue_from Pundit::NotAuthorizedError, with: :policy_prohibited
    rescue_from JWT::VerificationError, JWT::DecodeError, with: :token_invalid
    rescue_from JWT::ExpiredSignature, with: :token_expired
    rescue_from Auth::Error::NotAuthorized, with: :auth_method_prohibited
  end

  def token_invalid(exception) # rubocop:disable Lint/UnusedMethodArgument
    render_error 401, 'error.auth.token.invalid'
  end

  def token_expired(exception) # rubocop:disable Lint/UnusedMethodArgument
    render_error 401, 'error.auth.token.expired'
  end

  def auth_method_prohibited(exception) # rubocop:disable Lint/UnusedMethodArgument
    render_error 401, 'error.auth.method.prohibited'
  end

  def policy_prohibited(exception)
    @class  = exception.policy.class.to_s.delete('Policy')
    @query  = exception.query.to_s.delete('?')

    render_error 403, 'error.policy.prohibited', class: @class, query: @query
  end

  def record_missing(exception)
    render_error 404, 'error.record.missing', record: exception.model
  end

  def record_invalid(exception)
    @record = exception.record
    @fields = @record.errors
    @class = @record.class.name

    render_error 404, 'error.record.invalid', @fields, record: @class
  end

  def render_error(status, message, fields = nil, **kwargs)
    error = {
      message: I18n.t(message, **kwargs)
    }
    error[:fields] = fields unless fields.nil?

    render json: { errors: [error], data: {} }, status: status
  end
end
