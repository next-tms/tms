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
      str += delivery_eta_on.to_s || ''
      str += delivery_appointment_at.to_s || ''
      str += delivery_appointment_on.to_s || ''
      str += delivery_hours_end_at.to_s || ''
      str += delivery_hours_start_at.to_s || ''
      str += flattened_items&.to_json || ''
      str += pickup_hours_end_at || ''
      str += pickup_hours_start_at || ''
      str += pro || ''
      str += quote_id || ''
      str += receiver_name || ''
      str += receiver_address.pretty(', ') unless receiver_address.blank?
      str += shipper_name || ''
      str += shipper_address.pretty(', ') unless shipper_address.blank?
      str += shipper_bol || ''
      str += shipper_reference || ''
      str += total_charges_cents&.to_s || ''
      str += total_cost_cents&.to_s || ''
      str += tracking_carrier_id&.to_s || ''
      str += value_cents.to_s
  
      Digest::SHA2.hexdigest(str)
    end

    def fingerprint
      str = ''.dup
  
      unless flattened_items.blank?
        flattened_items.each do |flattened_item|
          str += flattened_item
                 .attributes
                 .except(
                   *%w[created_at updated_at]
                 )
                 .to_s
        end
      end
  
      str += accessorial_codes.to_json
      str += shipper_address.pretty(', ') unless shipper_address.blank?
      str += receiver_address.pretty(', ') unless receiver_address.blank?
  
      if !created_at.blank? && created_at.in_time_zone('America/Los_Angeles').to_date >= Date.parse('2022-01-09')
        str += value_cents.to_s
      end
  
      Digest::SHA2.hexdigest(str)
    end
  end
end
