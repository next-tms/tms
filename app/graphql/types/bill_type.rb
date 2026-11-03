module Types
  class BillType < Types::BaseObject
    description 'GraphQL Object for Bills a carrier bills the broker'

    field :balance_cents, Integer, null: false
    field :balance_currency, String, null: false
    field :due_on, GraphQL::Types::ISO8601Date
    field :id, ID, null: false
    field :invoice_number, String, method: :invoice
    field :number, String
    field :paid_cents, Integer, null: false
    field :paid_currency, String, null: false
    field :pro, String
    field :shipment, Types::ShipmentType, authorize: { raise: false, to: :view? }

    def number = shipment&.load_id&.to_s
    def shipment = dataloader.with(Sources::Association, PaymentTransaction, :shipment).load(object)
  end
end
