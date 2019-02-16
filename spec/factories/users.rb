FactoryBot.define do
  factory :user do
    name { Faker::Internet.unique.username }
    email { Faker::Internet.unique.safe_email }
    first_name { Faker::Name.first_name }
    middle_name { Faker::Name.middle_name }
    last_name { Faker::Name.last_name }
    password { Faker::Lorem.characters(10) }
    role { :user }

    trait :admin do
      role { :admin }
    end

    trait :moderator do
      role { :moderator }
    end

    trait :anonymous do
      id { User.anonymous.id }
      name { User.anonymous.name }
      email { User.anonymous.email }
      first_name { User.anonymous.first_name }
      middle_name { User.anonymous.middle_name }
      last_name { User.anonymous.last_name }
      role { User.anonymous.role }
      password { User.anonymous.password }
    end
  end
end
