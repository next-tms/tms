# frozen_string_literal: true

module Shipment::Interstellarable
  extend ActiveSupport::Concern

  included do
    def fetch_carrier_bol
      InterstellarDocumentService.carrier_bol(shipment: self)
    end

    def fetch_carrier_pod
      InterstellarDocumentService.carrier_pod(shipment: self)
    end

    def fetch_pro
      InterstellarProService.call(shipment: self)
    end

    def update_tracking_events
      UpdateShipmentTrackingEventsService.new(shipment: self).call
    end
  end
end
