require 'rails_helper'

RSpec.describe(Transponder::ORM::Territory) do
  let(:postal_codes) { [] }
  let(:region_abbreviation) { 'CA' }
  let(:territory) { described_class.new(country: { alpha2: 'US' }, postal_codes:, region_abbreviation:) }

  describe '#initialize' do
    it { expect(territory).to(have_attributes(country_alpha2: 'US', postal_codes: [], region_abbreviation: 'CA')) }
    it { expect(described_class.new(country: { alpha2: 'US' })).to(have_attributes(postal_codes: [], region_abbreviation: nil)) }
  end

  describe '#name' do
    it { expect(territory.name).to(eq('CA, US')) }

    context 'when the region is blank' do
      let(:region_abbreviation) { nil }

      it { expect(territory.name).to(eq('US')) }
    end
  end

  describe '#to_s' do
    it { expect(territory.to_s).to(eq('CA, US')) }

    context 'when the territory has postal codes' do
      let(:postal_codes) { ['850', '851'] }

      it { expect(territory.to_s).to(eq('CA, US (850, 851)')) }
    end
  end
end
