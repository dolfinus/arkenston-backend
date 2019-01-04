class GraphqlController < ApplicationController
  include ErrorHandler

  def execute
    begin
      variables = ensure_hash(params[:variables])
      query = params[:query]
      operation_name = params[:operationName]
      context = {
        # Query context goes here, for example:
        current_user: current_user
      }
      result = BackendSchema.execute(query, variables: variables, context: context, operation_name: operation_name)
      render json: result
    rescue ActiveRecord::RecordNotFound => exception
      not_found(exception)
    rescue Pundit::NotAuthorizedError => exception
      not_authorized(exception)
    end
  rescue => exception
    raise exception unless Rails.env.development?

    handle_error_in_development(exception)
  end

  # Handle form data, JSON body, or a blank value
  def ensure_hash(ambiguous_param)
    case ambiguous_param
    when String
      if ambiguous_param.present?
        ensure_hash(JSON.parse(ambiguous_param))
      else
        {}
      end
    when Hash, ActionController::Parameters
      ambiguous_param
    when nil
      {}
    else
      raise ArgumentError, "Unexpected parameter: #{ambiguous_param}"
    end
  end
end
