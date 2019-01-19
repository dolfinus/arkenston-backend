FactoryBot.define do
  factory :visitor, class: Auth::Visitor do
    id { Faker::Number.number(5) }
    role { 'user' }

    trait :admin do
      role { 'admin' }
    end

    trait :moderator do
      role { 'moderator' }
    end

    trait :anonymous do
      id { Auth::Visitor.anonymous.id }
      role { Auth::Visitor.anonymous.role }
    end

    initialize_with { new(attributes) }
  end
end
