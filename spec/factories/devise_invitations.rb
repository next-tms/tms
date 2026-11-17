FactoryBot.define do
  factory :devise_invitation, class: 'DeviseInvitable::Invitation' do
    invitation_accepted_at { '2022-06-29 23:58:27' }
    invitation_created_at { '2022-06-29 23:58:27' }
    invitation_sent_at { '2022-06-29 23:58:27' }
    invite_key { { email: Faker::Internet.email } }
    resource_created_at { '2022-06-29 23:58:27' }

    trait :pending do
      invitation_accepted_at { nil }
    end
  end
end
