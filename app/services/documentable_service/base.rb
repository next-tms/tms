# frozen_string_literal: true

module DocumentableService
  class Base
    class << self
      def call!(record, document_type)
        new(record, document_type).call!
      end
    end

    attr_reader :document_type, :record

    def initialize(record, document_type)
      record_class = "::#{self.class.to_s.demodulize}".constantize

      raise ArgumentError, "record must be a #{record_class}" unless record.is_a?(record_class)
      raise ArgumentError, 'document_type must be a Symbol' unless document_type.is_a?(Symbol)

      @document_type = document_type
      @record = record
    end

    def call!
      create_document if create_document?
    end

    private

    def attached?
      attachment.attached?
    end

    def attachment
      record.public_send(document_type)
    end

    def create_document
      attachment.purge if attached?

      document_job_class
      .perform_later(
        broker_documents_fingerprint: record.broker_documents_fingerprint,
        record:,
      )
    end

    def document_job_class
      "DocumentableService::#{record.class}::Create#{document_type.to_s.camelcase}Job".constantize
    end

    def create_document?
      !valid?
    end

    def fingerprint
      record.public_send("#{document_type}_fingerprint")
    end

    def valid?
      attached?
    end
  end
end
