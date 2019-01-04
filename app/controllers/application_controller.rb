class ApplicationController < ActionController::API
  include Clearance::Controller
  include Pundit
  before_action :set_paper_trail_whodunnit

  def current_user
    return User.anonymous if request.headers['Authorization'].blank?

    token = request.headers['Authorization'].split(' ').last
    return User.anonymous if token.blank?

    Auth::Token.verify(token)
  end

  def user_for_paper_trail
    current_user.id
  end
end
