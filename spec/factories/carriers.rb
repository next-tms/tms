# frozen_string_literal: true

# == Schema Information
#
# Table name: carriers
#
# @!attribute id
#   @return [Integer]
# @!attribute acts_as_broker
#   @return [Boolean]
# @!attribute consider_bol_and_pod_documents_same
#   @return [Boolean]
# @!attribute encrypted_api_key
#   @return [String]
# @!attribute encrypted_proxy_url
#   @return [String]
# @!attribute has_traceable_pickup_confirmation
#   @return [Boolean]
# @!attribute mc_number
#   @return [Integer]
# @!attribute name
#   @return [String]
# @!attribute scac
#   @return [String]
# @!attribute broker_billing_address_id
#   @return []
# @!attribute check_mailing_address_id
#   @return []
#
# Indexes
#
#  index_carriers_on_broker_billing_address_id  (broker_billing_address_id)
#  index_carriers_on_check_mailing_address_id   (check_mailing_address_id)
#  index_carriers_on_name                       (name) UNIQUE
#  index_carriers_on_scac                       (scac) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (broker_billing_address_id => addresses.id)
#  fk_rails_...  (check_mailing_address_id => addresses.id)
#
FactoryBot.define do
  factory :carrier do
    check_mailing_address_id { create(:address) }
    mc_number { Faker::Number.number.to_s[..5] }
    name { Faker::Company.name }
    scac { Faker::Alphanumeric.alpha[..3].upcase }
  end
end
