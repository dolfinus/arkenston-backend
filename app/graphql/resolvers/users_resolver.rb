class UsersResolver < ApplicationResolver
  include ModelPagination
  paginate User
end
