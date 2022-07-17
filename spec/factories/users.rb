# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
# @!attribute id
#   @return [Integer]
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
# @!attribute broker_customer_id
#   @return []
# @!attribute broker_id
#   @return [Integer]
# @!attribute contact_id
#   @return []
# @!attribute invited_by_id
#   @return []
#
# Indexes
#
#  index_users_on_broker_customer_id    (broker_customer_id)
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
#  fk_rails_...  (broker_customer_id => broker_customers.id)
#  fk_rails_...  (contact_id => contacts.id)
#  fk_rails_...  (invited_by_id => users.id)
#
FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { 'MyString' }
    encrypted_password { 'MyString' }
    reset_password_sent_at { '2022-06-29 23:58:27' }
    remember_created_at { '2022-06-29 23:58:27' }
    sign_in_count { 1 }
    current_sign_in_at { '2022-06-29 23:58:27' }
    last_sign_in_at { '2022-06-29 23:58:27' }
    current_sign_in_ip { '' }
    last_sign_in_ip { '' }
    confirmation_token { Faker::Number.number(digits: 10) }
    confirmed_at { '2022-06-29 23:58:27' }
    confirmation_sent_at { '2022-06-29 23:58:27' }
    unconfirmed_email { 'MyString' }
    failed_attempts { 1 }
    locked_at { '2022-06-29 23:58:27' }
    first_name { 'MyString' }
    updated_at { '2022-06-29 23:58:27' }
    broker { create(:broker) }
    phone { 'MyString' }
    receive_sms_notifications { false }
    last_name { 'MyString' }
    broker_customer {}
    receive_email_notifications { false }
    receive_notifications_from_self { false }
    contact {}
    invitation_created_at { '2022-06-29 23:58:27' }
    invitation_sent_at { '2022-06-29 23:58:27' }
    invitation_accepted_at { '2022-06-29 23:58:27' }
    invitation_limit { 1 }
    invitations_count { 1 }
    deactivated { false }
    time_zone_name { 'MyString' }
  end
end
