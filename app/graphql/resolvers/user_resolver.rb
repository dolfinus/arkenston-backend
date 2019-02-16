class UserResolver < ApplicationResolver
  include UserSeeker

  def resolve
    find_user_or_current(params)
  end
end
