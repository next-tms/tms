# frozen_string_literal: true

module Shipment::Documentable
  extend ActiveSupport::Concern

  included do
    after_save do
      broker_bol.purge unless broker_bol_valid?
    end

    after_save do
      broker_dispatch_sheet.purge unless broker_dispatch_sheet_valid?
    end

    after_save do
      broker_quote.purge unless broker_quote_valid?
    end

    has_one_attached :broker_bol
    has_one_attached :broker_dispatch_sheet
    has_one_attached :broker_quote
    has_one_attached :carrier_bol   # TODO: Rename to carrier_scanned_bol
    has_one_attached :carrier_label # TODO: Rename to carrier_bol
    has_one_attached :carrier_pod
    has_one_attached :broker_carrier_quote

    def broker_bol_valid?
      return false if broker_carrier&.as_interstellar_carrier&.bol_requires_tracking_number? && pro.blank?

      @broker_bol_valid ||= broker_bol.attached? && broker_bol_shipment_fingerprint == broker_documents_fingerprint
    end

    def broker_dispatch_sheet_valid?
      @broker_dispatch_sheet_valid ||= broker_dispatch_sheet.attached? && broker_dispatch_sheet_shipment_fingerprint == broker_documents_fingerprint
    end

    def broker_quote_valid?
      @broker_quote_valid ||= broker_quote.attached? && broker_quote_shipment_fingerprint == broker_documents_fingerprint
    end
  end
end
