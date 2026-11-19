class EBOL::Importer::Location
  class << self
    def call(location, address) = new(location, address).call
  end

  attr_reader :address, :location

  def initialize(location, address)
    @address = address
    @location = location || {}
  end

  def call
    {
      city: location[:city],
      country_alpha2: country&.alpha2,
      id: address&.id,
      name: location[:name],
      region_iso31662: region&.iso31662,
      street: location[:address1],
      street2: location[:address2],
      zip_code: location[:postalCode]
    }.compact
  end

  private

  def country
    return @country if defined?(@country)

    @country = Grid::ORM::Country.find_by(alpha3: location[:country].to_s.upcase)
  end

  def region = country&.regions&.find_by(abbreviation: location[:stateProvince].to_s.upcase)
end
