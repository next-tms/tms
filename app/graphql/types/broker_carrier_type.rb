# frozen_string_literal: true

module Types
  class BrokerCarrierType < Types::BaseObject
    field :id, ID, null: false
    field :carrier, Types::CarrierType
    field :broker, Types::BrokerType
    field :account, String
    field :account_desc, String
    field :default_bol_notes, String
    field :check_mailing_address_id, Integer
    field :broker_customer, Types::BrokerCustomerType
    field :days_to_pay_after_invoice_date, Integer
    field :create_invoice_on_pickup, Boolean
    field :quote_padding_cents, Integer, null: false
    field :quote_padding_currency, String, null: false
    field :accounting_notes, String
    field :shipments_count, Integer
    field :ignore_bol_requires_tracking_number, Boolean
    field :quickbooks_vendor_id, Integer
  end
end
