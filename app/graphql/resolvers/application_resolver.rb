class ApplicationResolver < ApplicationFunction
  include GraphQL::Sugar::Resolver

  def current_user
    context[:current_user]
  end
end
