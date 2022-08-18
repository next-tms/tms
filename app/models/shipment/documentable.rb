# frozen_string_literal: true

module Shipment::Documentable
  extend ActiveSupport::Concern
  include ActionView::RecordIdentifier

  included do
    has_one_attached :broker_bol
    has_one_attached :broker_dispatch_sheet
    has_one_attached :broker_label
    has_one_attached :broker_quote
    has_one_attached :carrier_bol   # TODO: Rename to carrier_scanned_bol
    has_one_attached :carrier_label # TODO: Rename to carrier_bol
    has_one_attached :carrier_pod
    has_one_attached :broker_carrier_quote

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
      target = "#{dom_id(self)}_#{document_type}"

      broadcast_replace_to(
        self,
        :documents,
        target:,
        html: "<tr id=\"#{target}\"></tr>".html_safe
      )
    end

    def broker_bol_valid?
      broker_bol.attached? && broker_bol_shipment_fingerprint == broker_documents_fingerprint
    end

    def broker_carrier_bol_requires_tracking_number?
      !!broker_carrier&.bol_requires_tracking_number?
    end

    def broker_dispatch_sheet_valid?
      broker_dispatch_sheet.attached? && broker_dispatch_sheet_shipment_fingerprint == broker_documents_fingerprint
    end

    def broker_quote_valid?
      broker_quote.attached? && broker_quote_shipment_fingerprint == broker_documents_fingerprint
    end

    def can_create_broker_bol?
      !incomplete? && !broker_bol_valid? && !(broker_carrier_bol_requires_tracking_number? && pro.blank?)
    end

    def can_create_broker_label?
      return true unless broker_label.attached?
    end

    def can_create_broker_dispatch_sheet?
      !incomplete? && !broker_dispatch_sheet_valid? && !(broker_carrier_bol_requires_tracking_number? && pro.blank?)
    end

    def can_create_broker_quote?
      !broker_quote_valid?
    end
  end

  def refresh_documents!
    return unless can_create_broker_bol? || can_create_broker_quote? || can_create_broker_label?

    domain = broker.websites.first.homepage_domain

    if can_create_broker_quote?
      broker_quote.purge
      CreateShipmentBrokerQuoteJob.perform_later(broker_documents_fingerprint:, domain:, shipment: self)
    end

    if can_create_broker_bol?
      broker_bol.purge
      broker_label.purge # for can_create_broker_label? below
      CreateShipmentBrokerBolJob.perform_later(broker_documents_fingerprint:, domain:, shipment: self)
    end

    if can_create_broker_label?
      broker_label.purge
      CreateShipmentBrokerLabelJob.perform_later(broker_documents_fingerprint:, shipment: self)
    end

    return unless can_create_broker_dispatch_sheet?

    broker_dispatch_sheet.purge
    CreateShipmentBrokerDispatchSheetJob.perform_later(broker_documents_fingerprint:, domain:, shipment: self)
  end
end
