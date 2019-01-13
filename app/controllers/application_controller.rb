class ApplicationController < ActionController::API
  include Clearance::Controller
  include ErrorHandler
  include Pundit

  before_action :set_paper_trail_whodunnit

  def http_auth_header
    header = request.headers['Authorization']
    return nil if header.blank?

    type, token = header.split(' ')
    return nil if token.blank?

    [type.downcase.inquiry, token]
  end

  def current_user
    result = http_auth_header
    return Auth::Visitor.anonymous unless result

    type, token = result
    if type.bearer?
      Auth::Token.verify(token, :access)
    elsif type.basic?
      raise Auth::Error.not_allowed
    else
      Auth::Visitor.anonymous
    end
  end

  def user_for_paper_trail
    current_user
  end
end
