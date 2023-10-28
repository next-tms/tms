# frozen_string_literal: true

module Shipment::Transponible
  extend ActiveSupport::Concern

  included do
    def fetch_carrier_bol
      TransponderService::FetchDocument.call(self, :bol)
    end

    def fetch_carrier_pod
      TransponderService::FetchDocument.call(self, :pod)
    end

    def fetch_pro
      TransponderService::FetchPro.call(self)
    end

    # @return [Boolean]
    def update_tracking_events
      TransponderService::FetchTracking.call(self)
    end
  end
end
