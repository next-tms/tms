# frozen_inputing_literal: true

module Shipment::Fingerprintable
  extend ActiveSupport::Concern

  included do
    before_save :set_fingerprint
  end

  def fingerprint
    super.presence || set_fingerprint
  end

  private

  def set_fingerprint
    parts = []

    if flattened_items.present?
      flattened_items.each do |flattened_item|
        parts << flattened_item
                 .attributes
                 .except('created_at', 'updated_at')
                 .to_s
      end
    end

    parts << accessorial_codes.to_json
    parts << shipper_address.pretty(', ') if shipper_address.present?
    parts << receiver_address.pretty(', ') if receiver_address.present?

    if created_at.present?
      date = created_at.in_time_zone('America/Los_Angeles').to_date

      case date
      when (Date.parse('2022-01-09')..) then parts << value_cents.to_s
      when (Date.parse('2023-07-21')..) then parts << calculated_freight_classes?.to_s
      end
    end

    self.fingerprint = Digest::SHA2.hexdigest(parts.join)
  end
end
