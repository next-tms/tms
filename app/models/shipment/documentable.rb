# frozen_string_literal: true

module Shipment::Documentable
  extend ActiveSupport::Concern
  include ActionView::RecordIdentifier
  include ActionView::Helpers::UrlHelper # For link_to

  included do
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

    def broadcast_document_generation_started(document_type)
      broadcast_update_to(
        self,
        :documents,
        target: "#{dom_id(self)}_document_notification",
        html: <<~HTML.html_safe
          <div class="alert alert-info">
            <div class="d-flex align-items-center">
              Some documents are being generated.
              <div class="spinner-border ms-auto" role="status" aria-hidden="true"></div>
            </div>
          </div>
        HTML
      )
    end

    def broadcast_new_document_generated(document_type)
      host = Rails.env.development? ? 'localhost:3000' : broker.websites.last.domain

      broadcast_update_to(
        self,
        :documents,
        target: "#{dom_id(self)}_document_notification",
        html: <<~HTML.html_safe
          <div class="alert alert-success">
            <div class="d-flex align-items-center">
              New documents are available,
              #{link_to Rails.application.routes.url_helpers.documents_broker_shipment_url(load_id, host:)}
              to view them.
            </div>
          </div>
        HTML
      )

      broadcast_append_to(
        self,
        :documents,
        target: "#{dom_id(self)}_documents_table_body",
        html: <<~HTML.html_safe
          <tr>
            <td>#{broker.name}</td>
            <td>#{document_type}</td>
          </tr>
        HTML
      )
    end
  end
end
