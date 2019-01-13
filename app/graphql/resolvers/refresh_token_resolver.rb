class RefreshTokenResolver < ApplicationResolver
  parameter :token, types.String

  def resolve
    Auth::Token.verify(params[:token], :refresh)
  end
end
