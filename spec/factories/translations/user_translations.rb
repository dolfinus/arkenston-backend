FactoryBot.define do
  non_default_locales = I18n.available_locales - [I18n.default_locale]

  factory :user_translation, class: Hash do
    locale { I18n.default_locale }
    first_name { Faker::Name.first_name }
    middle_name { Faker::Name.middle_name }
    last_name { Faker::Name.last_name }

    trait :known_locale do
      locale { non_default_locales.sample }
    end

    trait :unknown_locale do
      locale { Faker::Lorem.word }
    end

    initialize_with { attributes }
  end
end
