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
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute broker_billing_address_id
#   @return []
# @!attribute check_mailing_address_id
#   @return []
#
# Indexes
#
#  index_carriers_on_broker_billing_address_id  (broker_billing_address_id)
#  index_carriers_on_check_mailing_address_id   (check_mailing_address_id)
#  index_carriers_on_mc_number                  (mc_number) UNIQUE
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
    sequence(:name) { |number| "#{Faker::Company.name} #{number}" }
    sequence(:scac) { |number| format('%04d', number % 10_000) }

    check_mailing_address_id { create(:address) }
    mc_number { Faker::Number.number.to_s[..5] }
  end
end
