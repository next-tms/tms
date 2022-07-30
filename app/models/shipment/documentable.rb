# frozen_string_literal: true

module Shipment::Documentable
  extend ActiveSupport::Concern
  include ActionView::RecordIdentifier

  included do
    after_commit { refresh_documents }

    after_save do
      broker_bol.purge unless broker_bol_valid?
    end

    after_save do
      broker_dispatch_sheet.purge unless broker_dispatch_sheet_valid?
    end

    after_save do
      broker_label.purge unless broker_bol_valid?
    end

    after_save do
      broker_quote.purge unless broker_quote_valid?
    end

    has_one_attached :broker_bol
    has_one_attached :broker_dispatch_sheet
    has_one_attached :broker_label
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

    def broadcast_new_document_generated(document_type)
      partial = if %i[broker_dispatch_sheet broker_carrier_quote].include?(document_type)
                  "broker/shipments/documents/#{document_type}"
                else
                  "shipments/documents/#{document_type}"
                end

      broadcast_replace_to(
        self,
        :documents,
        target: "#{dom_id(self)}_#{document_type}",
        html: ApplicationController.render(partial:, locals: { this_dom_id: dom_id(self), shipment: self }).html_safe
      )
    end

    def broadcast_outdated_document(document_type)
      partial = if %i[broker_dispatch_sheet broker_carrier_quote].include?(document_type)
                  "broker/shipments/documents/#{document_type}"
                else
                  "shipments/documents/#{document_type}"
                end

      target = "#{dom_id(self)}_#{document_type}"

      broadcast_replace_to(
        self,
        :documents,
        target:,
        html: "<tr id=\"#{target}\"></tr>".html_safe
      )
    end
  end

  private

  def refresh_documents
    domain = broker.websites.first.homepage_domain

    CreateShipmentBrokerQuoteJob.perform_later(domain:, shipment: self) unless broker_quote_valid?

    return if incomplete?

    unless broker_bol_valid?
      CreateShipmentBrokerBolJob.perform_later(domain:, shipment: self)
      CreateShipmentBrokerLabelJob.perform_later(shipment: self)
    end

    CreateShipmentBrokerDispatchSheetJob.perform_later(domain:, shipment: self) unless broker_dispatch_sheet_valid?
  end
end
