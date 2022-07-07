FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { 'MyString' }
    encrypted_password { "MyString" }
    reset_password_sent_at { "2022-06-29 23:58:27" }
    remember_created_at { "2022-06-29 23:58:27" }
    sign_in_count { 1 }
    current_sign_in_at { "2022-06-29 23:58:27" }
    last_sign_in_at { "2022-06-29 23:58:27" }
    current_sign_in_ip { "" }
    last_sign_in_ip { "" }
    confirmation_token { Faker::Number.number(digits: 10) }
    confirmed_at { "2022-06-29 23:58:27" }
    confirmation_sent_at { "2022-06-29 23:58:27" }
    unconfirmed_email { "MyString" }
    failed_attempts { 1 }
    locked_at { "2022-06-29 23:58:27" }
    first_name { "MyString" }
    updated_at { "2022-06-29 23:58:27" }
    broker { create(:broker) }
    phone { "MyString" }
    receive_sms_notifications { false }
    last_name { "MyString" }
    broker_customer { }
    receive_email_notifications { false }
    receive_notifications_from_self { false }
    contact { }
    invitation_created_at { "2022-06-29 23:58:27" }
    invitation_sent_at { "2022-06-29 23:58:27" }
    invitation_accepted_at { "2022-06-29 23:58:27" }
    invitation_limit { 1 }
    invitations_count { 1 }
    deactivated { false }
    time_zone_name { "MyString" }
  end
end
