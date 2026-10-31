require 'rails_helper'

RSpec.describe(CountriesHelper) do
  describe '#country_options' do
    let(:countries) { Transponder::ORM::Country.where(alpha2: ['CA', 'US']).order(:name) }

    it { expect(helper.country_options(countries, 'US')).to(eq([['Canada', 'CA'], ['United States of America', 'US']])) }
    it { expect(helper.country_options(countries, nil)).to(eq([['Canada', 'CA'], ['United States of America', 'US']])) }

    context 'when the saved country is not in the list' do
      it { expect(helper.country_options(countries, 'MX').first).to(eq(['Mexico', 'MX'])) }
      it { expect(helper.country_options(countries, 'MX').size).to(eq(3)) }
    end

    context 'when Transponder no longer returns the saved country' do
      it { expect(helper.country_options(countries, 'ZZ').first).to(eq(['ZZ', 'ZZ'])) }
    end
  end
end
