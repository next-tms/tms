require 'rails_helper'

RSpec.describe(Address) do
  let(:address) { build(:address, city: 'Fremont', street: '4011 Lana Tier', zip_code: '94536') }

  describe '.ransackable_associations' do
    it { expect(described_class.ransackable_associations).to(be_empty) }
  end

  describe '.ransackable_attributes' do
    it { expect(described_class.ransackable_attributes).to(include('country_alpha2', 'region_iso31662')) }
  end

  describe '.with_zip_code' do
    let!(:address) { create(:address, zip_code: '90210-1234') }

    it { expect(described_class.with_zip_code('90210')).to(include(address)) }
    it { expect(described_class.with_zip_code('90211')).not_to(include(address)) }
    it { expect(described_class.with_zip_code('90210-9999')).to(include(address)) }
  end

  describe '#country' do
    it { expect(address.country).to(equal(Transponder::ORM::Country.find('US'))) }
  end

  describe '#find_or_build_standardized_address' do
    let(:key) { '4011 Lana Tier, Fremont, CA 94536' }
    let(:standardized_address) { address.tap(&:find_or_build_standardized_address).standardized_address }

    it { expect(standardized_address.country_alpha2).to(eq('US')) }
    it { expect(standardized_address.region_iso31662).to(eq('US-CA')) }
    it { expect(standardized_address).to(be_new_record) }

    context 'when a standardized address with the same key exists in the country' do
      let!(:existing_standardized_address) { create(:standardized_address, key:) }

      it { expect(standardized_address).to(eq(existing_standardized_address)) }
    end

    context 'when a standardized address with the same key exists in another country' do
      before { create(:standardized_address, country_alpha2: 'CA', key:, region_iso31662: 'CA-ON') }

      it { expect(standardized_address).to(be_new_record) }
    end
  end

  describe '#blank_to_nil' do
    it { expect(address.blank_to_nil('')).to(be_nil) }
    it { expect(address.blank_to_nil('Fremont')).to(eq('Fremont')) }
  end

  describe '#full_address?' do
    it { expect(address.full_address?).to(be(true)) }

    context 'when the street is blank' do
      before { address.street = nil }

      it { expect(address.full_address?).to(be(false)) }
    end
  end

  describe '#locality' do
    it { expect(address.locality).to(eq('Fremont, CA')) }
  end

  describe 'standardized address predicates' do
    let(:standardized_address) do
      instance_double(
        StandardizedAddress,
        commercial?: true,
        permanently_closed?: false,
        residential?: false,
        restaurant?: true,
        types: ['commercial']
      )
    end

    before { allow(address).to(receive(:standardized_address).and_return(standardized_address)) }

    it { expect(address.commercial?).to(be(true)) }
    it { expect(address.permanently_closed?).to(be(false)) }
    it { expect(address.residential?).to(be(false)) }
    it { expect(address.restaurant?).to(be(true)) }
    it { expect(address.types).to(eq(['commercial'])) }

    context 'when there is no standardized address' do
      let(:standardized_address) { nil }

      it { expect(address.commercial?).to(be_nil) }
      it { expect(address.permanently_closed?).to(be_nil) }
      it { expect(address.residential?).to(be_nil) }
      it { expect(address.restaurant?).to(be_nil) }
      it { expect(address.types).to(eq([])) }
    end
  end

  describe '#region' do
    it { expect(address.region).to(equal(Transponder::ORM::Region.find('US-CA'))) }
  end

  describe '#to_accounting_address' do
    it { expect(address.to_accounting_address).to(have_attributes(city: 'Fremont', country: 'US', line1: '4011 Lana Tier', region: 'CA')) }
  end

  describe '#to_transponder_graphql_input' do
    it { expect(address.to_transponder_graphql_input[:country]).to(eq({ alpha3: 'USA' })) }
    it { expect(address.to_transponder_graphql_input[:regionAbbreviation]).to(eq('CA')) }
  end

  describe 'validations' do
    before { address.validate }

    it { expect(address.errors).to(be_empty) }

    context 'when the country is blank' do
      let(:address) { build(:address, country_alpha2: nil) }

      it { expect(address.country_alpha2).to(eq('US')) }
    end

    context 'when the region is not within the country' do
      let(:address) { build(:address, country_alpha2: 'CA') }

      it { expect(address.errors[:region]).to(include("isn't within Canada")) }
    end

    context 'when the region code is unknown' do
      let(:address) { build(:address, region_iso31662: 'US-ZZ') }

      it { expect(address.errors.of_kind?(:region, :invalid)).to(be(true)) }
    end
  end
end
