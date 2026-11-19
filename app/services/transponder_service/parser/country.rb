module TransponderService
  module Parser
    class Country
      class << self
        # alpha2 comes first because Transponder's tracking locations still use retired alpha3 codes (e.g. ROM for ROU)
        # @return [Grid::ORM::Country|NilClass]
        def call(transponder_country)
          if transponder_country[:alpha2].present?
            Grid::ORM::Country.find_by(alpha2: transponder_country[:alpha2])
          elsif transponder_country[:alpha3].present?
            Grid::ORM::Country.find_by(alpha3: transponder_country[:alpha3])
          end
        end
      end
    end
  end
end
