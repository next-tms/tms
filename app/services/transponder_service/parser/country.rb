module TransponderService
  module Parser
    class Country
      class << self
        # @return [Boolean|NilClass]
        def call(transponder_country)
          if transponder_country[:alpha3].present?
            ::Country.find_by(alpha3_code: transponder_country[:alpha3])
          elsif transponder_country[:alpha2].present?
            ::Country.find_by(alpha2_code: transponder_country[:alpha2])
          end
        end
      end
    end
  end
end
