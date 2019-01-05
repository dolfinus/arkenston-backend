FactoryBot.define do
  factory :user_translation, class: Hash do
    locale { Faker::Lorem.word }
    first_name { Faker::Name.first_name }
    middle_name { Faker::Name.middle_name }
    last_name { Faker::Name.last_name }

    initialize_with { attributes }
  end
end
