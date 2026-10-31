module HasAPI
  class ErrorParser
    class << self
      def call(record)
        new(record).call
      end
    end

    ENFORCED_API_ERROR_CODE_MESSAGES = {
      api_error: 'API error, try again later',
      invalid_credentials_error: 'Authentication error, please update your credentials',
      not_implemented_error: 'API quoting not supported',
      unknown_carrier_error: 'API quoting not supported'
    }.freeze
    FALLBACK_API_ERROR_CODE_MESSAGES = {
      not_serviceable_error: "Not serviceable, but carrier didn't explain why"
    }.freeze

    attr_reader :record

    delegate :api_errors, to: :record

    def initialize(record)
      raise ArgumentError, 'record.api_backed? must be true' unless record.try(:api_backed?)

      @record = record
    end

    def call
      return [] if record.api_errors.blank?

      parse_api_errors
    end

    private

    def fix_grammar(message)
      return if message.blank?

      message.gsub(/zip code/i, 'ZIP code')
    end

    def parse_api_errors
      messages = api_errors.map do |api_error|
        code = api_error.dig('extensions', 'code')&.downcase&.to_sym
        if code.present? && ENFORCED_API_ERROR_CODE_MESSAGES.include?(code)
          ENFORCED_API_ERROR_CODE_MESSAGES[code]
        elsif code.present?
          if api_error['message'] == 'GraphQL::ExecutionError'
            FALLBACK_API_ERROR_CODE_MESSAGES[code]
          else
            fix_grammar(api_error['message']).presence || FALLBACK_API_ERROR_CODE_MESSAGES[code]
          end
        else
          fix_grammar(api_error['message']).presence
        end
      end

      messages.compact_blank
    end
  end
end
