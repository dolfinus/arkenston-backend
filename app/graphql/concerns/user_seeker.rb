module UserSeeker
  extend ActiveSupport::Concern

  included do
    parameter :id,    types.ID
    parameter :name,  types.String
    parameter :email, types.String
  end

  def find_user(input)
    unique = User.filtrate_uniq_fields(input)
    user = User.find_uniq(unique)
    raise Auth::Error.not_found if user.nil? && !unique.empty?

    user
  end

  def find_user!(input)
    user = find_user(input)
    raise Auth::Error.not_found if user.nil?
  end

  def find_user_or_current(input)
    user = find_user(input)
    user ||= current_user
    user
  end
end
