class ApplicationController < ActionController::API
  include ErrorHandler
  include Pundit

  attr_reader :visitor
  before_action :set_visitor
  before_action :set_paper_trail_whodunnit

  def http_auth_header
    header = request.headers['Authorization']
    return nil if header.blank?

    type, token = header.split(' ')
    return nil if token.blank?

    [type.downcase.inquiry, token]
  end

  def set_visitor
    result = http_auth_header
    return @visitor = Auth::Visitor.anonymous unless result

    type, token = result
    raise Auth::Error.not_allowed unless type.bearer?

    @visitor = Auth::Token.verify(token, :access)
  end

  def current_user
    @visitor
  end

  def user_for_paper_trail
    current_user
  end
end
