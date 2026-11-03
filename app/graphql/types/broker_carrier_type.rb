module Types
  class BrokerCarrierType < Types::BaseObject
    description 'GraphQL Object for Broker Carrier Model'

    field :account, String
    field :account_desc, String
    field :accounting_notes, String, visible_to: :view_internal_notes?
    field :accounting_vendor_id, Integer
    field :broker_customer, Types::BrokerCustomerType, authorize: { raise: false, to: :view? }
    field :carrier, Types::CarrierType, authorize: { raise: false, to: :view? }
    field :check_mailing_address_id, Integer
    field :create_invoice_on_pickup, Boolean
    field :days_to_pay_after_invoice_date, Integer
    field :default_bol_notes, String
    field :id, ID, null: false
    field :ignore_bol_requires_tracking_number, Boolean
    field :quote_padding_cents, Integer, visible_to: :view_markup?
    field :quote_padding_currency, String, visible_to: :view_markup?
    field :shipments, Types::ShipmentCollectionType, null: false, resolver: Resolvers::ShipmentsResolver
    field :shipments_count, Integer

    def broker_customer = dataloader.with(Sources::Association, BrokerCarrier, :broker_customer).load(object)
    def carrier = dataloader.with(Sources::Association, BrokerCarrier, :carrier).load(object)
  end
end
