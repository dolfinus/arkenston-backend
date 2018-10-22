class UsersResolver < UserResolver

  def resolve
    User.all
  end
end
