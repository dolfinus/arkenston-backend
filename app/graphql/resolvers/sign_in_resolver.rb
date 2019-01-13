class SignInResolver < ApplicationResolver
  parameter :id,       types.ID
  parameter :name,     types.String
  parameter :email,    types.String
  parameter :password, types.String

  def resolve
    Auth::Basic.verify(params)
  end
end
