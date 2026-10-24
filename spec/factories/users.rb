# == Schema Information
#
# Table name: users
#
# @!attribute id
#   @return [Integer]
# @!attribute companyable_type
#   @return [String]
# @!attribute confirmation_sent_at
#   @return [Time]
# @!attribute confirmation_token
#   @return [String]
# @!attribute confirmed_at
#   @return [Time]
# @!attribute current_sign_in_at
#   @return [Time]
# @!attribute current_sign_in_ip
#   @return [String]
# @!attribute deactivated
#   @return [Boolean]
# @!attribute email
#   @return [String]
# @!attribute email_notifications_blacklist
#   @return [String]
# @!attribute encrypted_password
#   @return [String]
# @!attribute failed_attempts
#   @return [Integer]
# @!attribute first_name
#   @return [String]
# @!attribute invitation_accepted_at
#   @return [Time]
# @!attribute invitation_created_at
#   @return [Time]
# @!attribute invitation_limit
#   @return [Integer]
# @!attribute invitation_sent_at
#   @return [Time]
# @!attribute invitation_token
#   @return [String]
# @!attribute invitations_count
#   @return [Integer]
# @!attribute last_name
#   @return [String]
# @!attribute last_sign_in_at
#   @return [Time]
# @!attribute last_sign_in_ip
#   @return [String]
# @!attribute locked_at
#   @return [Time]
# @!attribute phone
#   @return [String]
# @!attribute receive_email_notifications
#   @return [Boolean]
# @!attribute receive_notifications_from_self
#   @return [Boolean]
# @!attribute receive_read_notifications_by_email
#   @return [Boolean]
# @!attribute receive_sms_notifications
#   @return [Boolean]
# @!attribute remember_created_at
#   @return [Time]
# @!attribute reset_password_sent_at
#   @return [Time]
# @!attribute reset_password_token
#   @return [String]
# @!attribute sign_in_count
#   @return [Integer]
# @!attribute time_zone_name
#   @return [String]
# @!attribute unconfirmed_email
#   @return [String]
# @!attribute unlock_token
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute companyable_id
#   @return []
# @!attribute contact_id
#   @return []
# @!attribute invited_by_id
#   @return []
#
# Indexes
#
#  index_users_on_companyable           (companyable_type,companyable_id)
#  index_users_on_confirmation_token    (confirmation_token) UNIQUE
#  index_users_on_contact_id            (contact_id)
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_invitation_token      (invitation_token) UNIQUE
#  index_users_on_invited_by_id         (invited_by_id)
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_unlock_token          (unlock_token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (contact_id => contacts.id)
#  fk_rails_...  (invited_by_id => users.id)
#
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
        after(:create) do |record|
          record.contact.contact_roles.create!(role: :root)
        end
      end
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
