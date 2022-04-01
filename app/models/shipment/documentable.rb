# frozen_string_literal: true

module Shipment::Documentable
  extend ActiveSupport::Concern

  included do
    # Remove broker documents when cost/charge changes

    before_save do
      broker_bol.purge if will_save_change_to_total_cost_cents? || will_save_change_to_total_charges_cents?
    end

    before_save do
      broker_dispatch_sheet.purge if will_save_change_to_total_cost_cents? || will_save_change_to_total_charges_cents?
    end

    before_save do
      broker_quote.purge if will_save_change_to_total_cost_cents? || will_save_change_to_total_charges_cents?
    end

    has_one_attached :broker_bol
    has_one_attached :broker_dispatch_sheet
    has_one_attached :broker_quote
    has_one_attached :carrier_bol   # TODO: Rename to carrier_scanned_bol
    has_one_attached :carrier_label # TODO: Rename to carrier_bol
    has_one_attached :carrier_pod

    def broker_bol_valid?
      return false if broker_carrier&.as_interstellar_carrier&.bol_requires_tracking_number? && pro.blank?

      @broker_bol_valid ||= !broker_bol.blank? && broker_bol_shipment_fingerprint == broker_documents_fingerprint
    end

    def broker_dispatch_sheet_valid?
      @broker_dispatch_sheet_valid ||= !broker_dispatch_sheet.blank? && broker_dispatch_sheet_shipment_fingerprint == broker_documents_fingerprint
    end

    def broker_quote_valid?
      @broker_quote_valid ||= !broker_quote.blank? && broker_quote_shipment_fingerprint == broker_documents_fingerprint
    end
  end
end
