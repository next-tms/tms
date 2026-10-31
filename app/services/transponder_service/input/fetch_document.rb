module TransponderService
  module Input
    class FetchDocument < Base
      DOCUMENT_TYPES = %i[bol pod].freeze

      attr_reader :document_type

      def initialize(object, document_type:)
        raise ArgumentError, "document_type must be one of #{DOCUMENT_TYPES.join(', ')}" unless DOCUMENT_TYPES.include?(document_type)

        @document_type = document_type

        super
      end

      def build
        { document_type: document_type.to_s.upcase, tracking_number: object.pro }
      end
    end
  end
end
