module Accounting
  module QuickBooks
    class DocumentConnection < Connection
      def create(record)
        super
      rescue ::Quickbooks::IntuitRequestException => e
        raise unless e.message.include?('Duplicate Document Number Error')

        record_class.find_by(document_number: record.document_number) || raise
      end

      private

      def select_match(results)
        return results.first if results.count == 1

        results.entries.find { |entry| entry.private_note.exclude?('Void') }
      end
    end
  end
end
