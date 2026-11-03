module Types
  class TrackingEventType < Types::BaseObjectWithTimestamp
    delegate :name, to: :event

    description 'GraphQL Object for Tracking Event Model'

    field :city, String
    field :country_alpha2, String
    field :id, ID, null: false
    field :name, String, null: false
    field :occurred_at, GraphQL::Types::ISO8601DateTime, method: :at
    field :region_iso31662, String
    field :terminal, Types::TerminalType
    field :type_code, String, null: false
    field :zip_code, String

    def terminal = dataloader.with(Sources::Association, TrackingEvent, :terminal).load(object)
    def type_code = event.active_shipping_code
    def zip_code = dataloader.with(Sources::Association, TrackingEvent, :address).load(object)&.zip_code

    private

    def event = dataloader.with(Sources::Association, TrackingEvent, :event).load(object)
  end
end
