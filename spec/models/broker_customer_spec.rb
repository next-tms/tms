# frozen_string_literal: true

# == Schema Information
#
# Table name: broker_customers
#
# @!attribute id
#   @return []
# @!attribute always_show_quotes_based_on_calculated_classes
#   @return [Boolean]
# @!attribute can_quote
#   @return [Boolean]
# @!attribute default_bol_notes
#   @return [String]
# @!attribute default_upcharge_cents
#   @return [Integer]
# @!attribute default_upcharge_currency
#   @return [String]
# @!attribute default_upcharge_percentage
#   @return [Float]
# @!attribute enable_auto_freight_class
#   @return [Boolean]
# @!attribute ignore_value_on_api_quotes
#   @return [Boolean]
# @!attribute internal_notes
#   @return [String]
# @!attribute preferred_broker_carriers_kind
#   @return [String]
# @!attribute receivables_schedule
#   @return [String]
# @!attribute requires_carrier_bol_on_receivables
#   @return [Boolean]
# @!attribute requires_carrier_pod_on_receivables
#   @return [Boolean]
# @!attribute requires_charges_confirmed_on_receivables
#   @return [Boolean]
# @!attribute requires_customer_reference_number_on_receivables
#   @return [Boolean]
# @!attribute requires_shipment_delivery_before_receivable
#   @return [Boolean]
# @!attribute requires_shipment_shipper_reference_on_receivables
#   @return [Boolean]
# @!attribute shipment_string_patterns
#   @return [String]
# @!attribute valid_freight_classes
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute broker_id
#   @return []
# @!attribute customer_id
#   @return []
# @!attribute office_address_id
#   @return []
# @!attribute primary_pickup_address_id
#   @return []
# @!attribute quickbooks_customer_id
#   @return [String]
# @!attribute receivables_contact_id
#   @return []
#
# Indexes
#
#  index_broker_customers_on_broker_id                            (broker_id)
#  index_broker_customers_on_customer_id                          (customer_id)
#  index_broker_customers_on_office_address_id                    (office_address_id)
#  index_broker_customers_on_primary_pickup_address_id            (primary_pickup_address_id)
#  index_broker_customers_on_receivables_contact_id               (receivables_contact_id)
#  index_broker_customers_on_requires_carrier_bol_on_receivables  (requires_carrier_bol_on_receivables)
#  index_broker_customers_on_requires_carrier_pod_on_receivables  (requires_carrier_pod_on_receivables)
#
# Foreign Keys
#
#  fk_rails_...  (broker_id => brokers.id)
#  fk_rails_...  (customer_id => customers.id)
#  fk_rails_...  (office_address_id => addresses.id)
#  fk_rails_...  (primary_pickup_address_id => addresses.id)
#  fk_rails_...  (receivables_contact_id => contacts.id)
#
require 'rails_helper'

RSpec.describe(BrokerCustomer, type: :model) do
  it_behaves_like 'companyable'
end
