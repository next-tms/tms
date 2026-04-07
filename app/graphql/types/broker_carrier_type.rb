module Types
  class BrokerCarrierType < Types::BaseObject
    description 'GraphQL Object for Broker Carrier Model'

    field :account, String
    field :account_desc, String
    field :accounting_notes, String
    field :broker, Types::BrokerType
    field :broker_customer, Types::BrokerCustomerType
    field :carrier, Types::CarrierType
    field :check_mailing_address_id, Integer
    field :create_invoice_on_pickup, Boolean
    field :days_to_pay_after_invoice_date, Integer
    field :default_bol_notes, String
    field :id, ID, null: false
    field :ignore_bol_requires_tracking_number, Boolean
    field :quickbooks_vendor_id, Integer
    field :quote_padding_cents, Integer, null: false
    field :quote_padding_currency, String, null: false
    field :shipments_count, Integer
  end
end
