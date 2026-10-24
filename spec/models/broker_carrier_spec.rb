# == Schema Information
#
# Table name: broker_carriers
#
# @!attribute id
#   @return [Integer]
# @!attribute account
#   @return [String]
# @!attribute account_desc
#   @return [String]
# @!attribute accounting_notes
#   @return [String]
# @!attribute create_invoice_on_pickup
#   @return [Boolean]
# @!attribute days_to_pay_after_invoice_date
#   @return [Integer]
# @!attribute default_bol_notes
#   @return [String]
# @!attribute encrypted_api_key
#   @return [String]
# @!attribute ignore_bol_requires_tracking_number
#   @return [Boolean]
# @!attribute password
#   @return [String]
# @!attribute quote_padding_cents
#   @return [Integer]
# @!attribute quote_padding_currency
#   @return [String]
# @!attribute shipments_count
#   @return [Integer]
# @!attribute username
#   @return [String]
# @!attribute website_password
#   @return [String]
# @!attribute website_username
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute accounting_vendor_id
#   @return [Integer]
# @!attribute broker_customer_id
#   @return []
# @!attribute carrier_id
#   @return [Integer]
# @!attribute check_mailing_address_id
#   @return []
#
# Indexes
#
#  index_broker_carriers_on_broker_customer_id        (broker_customer_id)
#  index_broker_carriers_on_carrier_id                (carrier_id)
#  index_broker_carriers_on_check_mailing_address_id  (check_mailing_address_id)
#  index_broker_carriers_on_shipments_count           (shipments_count)
#
# Foreign Keys
#
#  fk_rails_...  (broker_customer_id => broker_customers.id)
#  fk_rails_...  (carrier_id => carriers.id)
#  fk_rails_...  (check_mailing_address_id => addresses.id)
#
require 'rails_helper'

RSpec.describe(BrokerCarrier) do
  it_behaves_like 'accounting_syncable', resource: :vendor, record: 'Accounting::QuickBooks::Vendor'
  it_behaves_like 'companyable'
end
