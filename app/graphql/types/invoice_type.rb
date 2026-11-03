module Types
  class InvoiceType < Types::BaseObject
    description 'GraphQL Object for Invoices the broker bills a customer'

    field :balance_cents, Integer, null: false
    field :balance_currency, String, null: false
    field :document, Types::DocumentType
    field :due_on, GraphQL::Types::ISO8601Date
    field :id, ID, null: false
    field :issued_on, GraphQL::Types::ISO8601Date
    field :number, String, null: false
    field :paid_at, GraphQL::Types::ISO8601DateTime
    field :shipment, Types::ShipmentType, authorize: { raise: false, to: :view? }, null: false
    field :total_cents, Integer, null: false
    field :total_currency, String, null: false

    def document
      attachment = dataloader.with(Sources::Association, Receivable, :invoice_attachment).load(object)
      return unless attachment

      dataloader.with(Sources::Association, ActiveStorage::Attachment, :blob).load(attachment)
      attachment
    end

    def due_on = object.due_by&.in_time_zone(Setting.time_zone)&.to_date
    def issued_on = object.authorized_at&.in_time_zone(Setting.time_zone)&.to_date
    def number = shipment.load_id.to_s
    def shipment = dataloader.with(Sources::Association, Receivable, :shipment).load(object)
  end
end
