class BrokerWare::Location
  class << self
    def call(...) = new(...).call
  end

  DEFAULT_COUNTRY = 'USA'.freeze

  attr_reader :country_code, :zip_code

  def initialize(zip_code, country_code)
    @country_code = country_code.to_s.upcase.presence || DEFAULT_COUNTRY
    @zip_code = zip_code.to_s.squish
  end

  def call
    return if zip_code.blank? || country.nil? || region.nil?

    { city: verification.locality, country_alpha2: country.alpha2, region_iso31662: region.iso31662, zip_code: }
  end

  private

  def country
    return @country if defined?(@country)

    @country = Transponder::ORM::Country.find_by(country_attribute => country_code)
  end

  def country_attribute = country_code.length == 2 ? :alpha2 : :alpha3

  def region
    return @region if defined?(@region)

    @region = verification&.locality.present? ? country.regions.find_by(abbreviation: verification.administrative_area) : nil
  end

  def verification
    return @verification if defined?(@verification)

    @verification = Geo.verify(postal_code: zip_code, region_code: country.alpha2)
  end
end
