class ApplicationMutator < ApplicationFunction
  include GraphQL::Sugar::Mutator
  include ChecksPolicy

  def current_user
    context[:current_user]
  end
end
