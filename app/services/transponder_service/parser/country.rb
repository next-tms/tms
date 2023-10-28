# frozen_string_literal: true

module TransponderService
  module Parser
    class Country
      class << self
        # @return [Boolean|NilClass]
        def call(transponder_country)
          country = nil

          country = Country.find_by(alpha3_code: transponder_country[:alpha3]) if transponder_country[:alpha3].present?

          if transponder_country[:alpha2].present?
            country ||= Country.find_by(alpha2_code: transponder_country[:alpha2])
          end

          country
        end
      end
    end
  end
end
