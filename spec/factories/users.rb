FactoryBot.define do
  factory :user do
    name { Faker::Lorem.word }
    first_name { Faker::Name.first_name }
    middle_name { Faker::Name.middle_name }
    last_name { Faker::Name.last_name }
    email { Faker::Internet.safe_email }
    password { Faker::Lorem.characters(10) }
    role { :user }

    trait :admin do
      role { :admin }
    end

    trait :moderator do
      role { :moderator }
    end
  end
end
