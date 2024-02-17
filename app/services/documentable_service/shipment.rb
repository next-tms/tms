# frozen_string_literal: true

module DocumentableService
  class Shipment < Base
    private

    def create_document?
      return true if super && %i[broker_bol broker_dispatch_sheet].exclude?(document_type)

      return false if record.incomplete?

      return record.pro.present? if record.broker_carrier_bol_requires_tracking_number?

      true
    end

    def fingerprint
      record.public_send("#{document_type}_shipment_fingerprint")
    end

    def valid?
      super && fingerprint == record.broker_documents_fingerprint
    end
  end
end
