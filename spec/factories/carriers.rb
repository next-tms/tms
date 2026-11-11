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
# @!attribute has_traceable_pickup_confirmation
#   @return [Boolean]
# @!attribute legal_name
#   @return [String]
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
# @!attribute transponder_id
#   @return [String]
#
# Indexes
#
#  index_carriers_on_broker_billing_address_id  (broker_billing_address_id)
#  index_carriers_on_check_mailing_address_id   (check_mailing_address_id)
#  index_carriers_on_mc_number                  (mc_number) UNIQUE
#  index_carriers_on_name                       (name) UNIQUE
#  index_carriers_on_scac                       (scac) UNIQUE
#  index_carriers_on_transponder_id             (transponder_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (broker_billing_address_id => addresses.id)
#  fk_rails_...  (check_mailing_address_id => addresses.id)
#
# @!attribute id
#   @return [Integer]
# @!attribute acts_as_broker
#   @return [Boolean]
# @!attribute consider_bol_and_pod_documents_same
#   @return [Boolean]
# @!attribute has_traceable_pickup_confirmation
#   @return [Boolean]
# @!attribute legal_name
#   @return [String]
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
# @!attribute transponder_id
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
#  index_carriers_on_mc_number                  (mc_number) UNIQUE
#  index_carriers_on_name                       (name) UNIQUE
#  index_carriers_on_scac                       (scac) UNIQUE
#  index_carriers_on_transponder_id             (transponder_id) UNIQUE
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

    trait :saia do
      scac { 'SAIA' }
      transponder_id { '26a6a0c0-2e95-4835-ad73-4a3c8bb38cdd' }
    end

    trait :tql do
      acts_as_broker { true }
      consider_bol_and_pod_documents_same { true }
      scac { 'TQYL' }
      transponder_id { '8f0c3b52-6b1e-4b8e-9a51-3f2f0d7c1e44' }
    end
  end
end
