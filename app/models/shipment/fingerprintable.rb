# frozen_string_literal: true

module Shipment::Fingerprintable
  extend ActiveSupport::Concern

  included do
    def broker_documents_fingerprint
      str = ''.dup
      str += accessorial_codes&.to_json || ''
      str += bol || ''
      str += bol_notes || ''
      str += broker_carrier_id&.to_s || ''
      str += delivery_appointment_at.to_s || ''
      str += delivery_appointment_on.to_s || ''
      str += delivery_eta_on.to_s || ''
      str += delivery_hours_end_at.to_s || ''
      str += delivery_hours_start_at.to_s || ''
      str += flattened_items&.to_json || ''
      str += pickup_hours_end_at || ''
      str += pickup_hours_start_at || ''
      str += pickup_on&.to_s || ''
      str += pro || ''
      str += quote_id || ''
      str += receiver_address.pretty(', ') if receiver_address.present?
      str += receiver_name || ''
      str += shipper_address.pretty(', ') if shipper_address.present?
      str += shipper_bol || ''
      str += shipper_name || ''
      str += shipper_reference || ''
      str += total_charges_cents&.to_s || ''
      str += total_charges_cents&.to_s || ''
      str += total_cost_cents&.to_s || ''
      str += total_cost_cents&.to_s || ''
      str += tracking_carrier_id&.to_s || ''
      str += value_cents.to_s

      Digest::SHA2.hexdigest(str)
    end

    def fingerprint
      str = ''.dup

      if flattened_items.present?
        flattened_items.each do |flattened_item|
          str += flattened_item
                 .attributes
                 .except(
                   'created_at', 'updated_at'
                 )
                 .to_s
        end
      end

      str += accessorial_codes.to_json
      str += shipper_address.pretty(', ') if shipper_address.present?
      str += receiver_address.pretty(', ') if receiver_address.present?

      if created_at.present?
        if created_at.in_time_zone('America/Los_Angeles').to_date >= Date.parse('2022-01-09')
          str += value_cents.to_s
        end

        if created_at.in_time_zone('America/Los_Angeles').to_date >= Date.parse('2023-07-06')
          str += linear_ft.to_s
        end
      end

      Digest::SHA2.hexdigest(str)
    end
  end
end
