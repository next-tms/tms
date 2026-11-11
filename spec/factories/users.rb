FactoryBot.define do
  factory :user do
    confirmation_sent_at { '2022-06-29 23:58:27' }
    confirmation_token { Faker::Number.number(digits: 10) }
    confirmed_at { '2022-06-29 23:58:27' }
    contact { association(:contact, companyable:) }
    current_sign_in_at { '2022-06-29 23:58:27' }
    current_sign_in_ip { '' }
    deactivated { false }
    email { Faker::Internet.email }
    failed_attempts { 1 }
    first_name { Faker::Name.first_name }
    invitation_accepted_at { '2022-06-29 23:58:27' }
    invitation_created_at { '2022-06-29 23:58:27' }
    invitation_limit { 1 }
    invitation_sent_at { '2022-06-29 23:58:27' }
    invitations_count { 1 }
    last_name { Faker::Name.last_name }
    last_sign_in_at { '2022-06-29 23:58:27' }
    last_sign_in_ip { '' }
    locked_at { '2022-06-29 23:58:27' }
    password { Faker::Internet.password }
    phone { Faker::PhoneNumber.cell_phone_in_e164 }
    receive_email_notifications { false }
    receive_notifications_from_self { false }
    receive_sms_notifications { false }
    remember_created_at { '2022-06-29 23:58:27' }
    reset_password_sent_at { '2022-06-29 23:58:27' }
    sign_in_count { 1 }
    time_zone_name { 'America/Los_Angeles' }
    unconfirmed_email { 'MyString' }
    updated_at { '2022-06-29 23:58:27' }

    factory :broker_user do
      companyable { nil }

      factory :root_broker_user do
        after(:create) { |record| record.contact.contact_roles.create!(role: :root) }
      end
    end

    factory :carrier_user do
      association :companyable, factory: :carrier
    end

    factory :customer_user do
      association :companyable, factory: :broker_customer
    end

    #    factory :dispatch_user do
    #      after(:build) do |record|
    #        record.roles << Role.find_or_create_by!(name: 'dispatch')
    #      end
    #    end
  end
end
