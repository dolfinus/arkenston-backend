module ErrorHandler
  def self.included(base)
    base.class_eval do
      def handle_error_in_development(exception)
        logger.error(exception.message)
        logger.error(exception.backtrace.join("\n"))

        render json: {
          error: {
            message: exception.message
          },
          data: {}
        },
        status: 500
      end

      def not_authorized(exception)
        @class  = exception.policy.class.to_s.delete('Policy')
        @model  = @class.downcase
        @field  = exception.query.to_s.sub('?', '')

        @is_action = exception.policy.action?(exception.query) ? 2 : 1

        render json: {
          error: {
            message: I18n.t(
              'error.not_allowed',
              class:  @class,
              action: @field,
              field:  @field,
              count:  @is_action
            ),
            code: "#{@model}.#{@field}.not_allowed"
          },
          data: {}
        },
        status: 403
      end

      def not_found(exception)
        @class = exception.model
        @model = @class.downcase
        render json: {
          error: {
            message: I18n.t(
              'error.not_found',
              class: @class
            ),
            code: "#{@model}.not_found"
          },
          data: {}
        },
        status: 404
      end
    end
  end
end
