require 'rails_helper'

RSpec.describe(BrokerCountry) do
  let(:broker_country) { described_class.new(country_alpha2:) }
  let(:country_alpha2) { 'CA' }

  describe '.countries' do
    before do
      described_class.create!(country_alpha2: 'US')
      described_class.create!(country_alpha2: 'CA')
    end

    it { expect(described_class.countries.pluck(:alpha2)).to(contain_exactly('CA', 'US')) }
  end

  describe '#country' do
    it { expect(broker_country.country).to(equal(Transponder::ORM::Country.find('CA'))) }
  end

  describe 'validations' do
    subject { broker_country }

    it { is_expected.to(validate_uniqueness_of(:country_alpha2)) }

    context 'when the country is blank' do
      let(:country_alpha2) { nil }

      before { broker_country.validate }

      it { expect(broker_country.errors.of_kind?(:country_alpha2, :blank)).to(be(true)) }
    end
  end
end
