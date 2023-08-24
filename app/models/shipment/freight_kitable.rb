# frozen_string_literal: true

module Shipment::FreightKitable
  extend ActiveSupport::Concern

  included do
    def fetch_carrier_bol
      FreightKitDocumentService.carrier_bol(shipment: self)
    end

    def fetch_carrier_pod
      FreightKitDocumentService.carrier_pod(shipment: self)
    end

    def fetch_pro
      FreightKitProService.call(shipment: self)
    end

    def update_tracking_events
      UpdateShipmentTrackingEventsService.new(shipment: self).call
    end
  end
end
