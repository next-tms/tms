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
    it { expect(described_class.with_zip_code('90210 9999')).to(include(address)) }

    context 'when the ZIP+4 is saved with a space' do
      let!(:address) { create(:address, zip_code: '90210 1234') }

      it { expect(address.zip_code).to(eq('90210-1234')) }
      it { expect(described_class.with_zip_code('90210')).to(include(address)) }
    end

    context 'when the postal code is not a ZIP+4' do
      let!(:address) { create(:address, country_alpha2: 'CA', region_iso31662: 'CA-ON', zip_code: 'K1A 0B1') }

      it { expect(address.zip_code).to(eq('K1A 0B1')) }
      it { expect(described_class.with_zip_code('K1A 0B1')).to(include(address)) }
    end
  end

  describe '#blank_to_nil' do
    it { expect(address.blank_to_nil('')).to(be_nil) }
    it { expect(address.blank_to_nil('Fremont')).to(eq('Fremont')) }
  end

  describe '#commercial?' do
    it { expect(address.commercial?).to(be(false)) }

    context 'when the address is a business' do
      before { address.business = true }

      it { expect(address.commercial?).to(be(true)) }
    end
  end

  describe '#country' do
    it { expect(address.country).to(equal(Grid::ORM::Country.find('US'))) }
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

  describe '#moved?' do
    it { expect(address.moved?).to(be(false)) }

    context 'when saved' do
      before { address.save! }

      it { expect(address.moved?).to(be(false)) }

      context 'when the street changes' do
        before { address.street = '4013 Lana Tier' }

        it { expect(address.moved?).to(be(true)) }
      end

      context 'when the street is cleared' do
        before { address.street = nil }

        it { expect(address.moved?).to(be(true)) }
      end

      context 'when only the name changes' do
        before { address.name = 'Acme' }

        it { expect(address.moved?).to(be(false)) }
      end
    end
  end

  describe '#postal_code?' do
    it { expect(address.postal_code?).to(be(true)) }

    context 'when the country has no postal codes' do
      before { allow(address).to(receive(:country).and_return(Grid::ORM::Country.new(alpha2: 'HK', postal_code: false))) }

      it { expect(address.postal_code?).to(be(false)) }
    end
  end

  describe '#region' do
    it { expect(address.region).to(equal(Grid::ORM::Region.find('US-CA'))) }
  end

  describe '#restaurant?' do
    it { expect(address.restaurant?).to(be(false)) }

    context 'when the place is a restaurant' do
      before { address.types = ['restaurant'] }

      it { expect(address.restaurant?).to(be(true)) }
    end
  end

  describe '#save' do
    let(:service) { instance_double(Address::StandardizeService, call: nil) }

    before do
      allow(Address::StandardizeService).to(receive(:new).and_return(service))
      address.save!
    end

    it { expect(Address::StandardizeService).to(have_received(:new).with(address:)) }

    context 'when a postal field changes' do
      before { address.update!(street: '4012 Lana Tier') }

      it { expect(service).to(have_received(:call).twice) }
    end

    context 'when the name changes' do
      before { address.update!(name: 'Taco Spot') }

      it { expect(service).to(have_received(:call).twice) }
    end

    context 'when no postal field changes' do
      before { address.update!(ref: 'Dock 4') }

      it { expect(service).to(have_received(:call).once) }
    end

    context 'when the address is not full' do
      let(:address) { build(:address, street: nil) }

      it { expect(Address::StandardizeService).not_to(have_received(:new)) }
    end
  end

  describe '#shipment' do
    it { expect(address.shipment).to(be_nil) }

    context 'with a receiver shipment' do
      let!(:shipment) { create(:shipment, receiver_address: address) }

      it { expect(address.shipment).to(eq(shipment)) }
    end

    context 'with a shipper shipment' do
      let!(:shipment) { create(:shipment, shipper_address: address) }

      it { expect(address.shipment).to(eq(shipment)) }
    end
  end

  describe '#standardize' do
    let(:service) { instance_double(Address::StandardizeService, call: nil) }

    before do
      allow(Address::StandardizeService).to(receive(:new).and_return(service))
      address.standardize
    end

    it { expect(Address::StandardizeService).to(have_received(:new).with(address:)) }

    context 'when called again' do
      before { address.standardize }

      it { expect(service).to(have_received(:call).once) }
    end

    context 'when called again after the name changes' do
      before do
        address.name = 'Taco Spot'
        address.standardize
      end

      it { expect(service).to(have_received(:call).twice) }
    end

    context 'when called again after a postal field changes' do
      before do
        address.street = '4012 Lana Tier'
        address.standardize
      end

      it { expect(service).to(have_received(:call).twice) }
    end

    context 'when saved after standardizing' do
      before { address.save! }

      it { expect(service).to(have_received(:call).once) }
    end
  end

  describe '#time_zone' do
    let(:address) { build(:address, time_zone_name: 'America/Chicago') }

    it { expect(address.time_zone.name).to(eq('America/Chicago')) }

    context 'without a time zone name' do
      let(:address) { build(:address, time_zone_name: nil) }

      it { expect(address.time_zone.name).to(eq('America/Los_Angeles')) }
    end
  end

  describe '#to_accounting_address' do
    it { expect(address.to_accounting_address).to(have_attributes(city: 'Fremont', country: 'US', line1: '4011 Lana Tier', region: 'CA')) }
  end

  describe '#to_postal_address' do
    it do
      expect(address.to_postal_address).to(
        eq(address_lines: ['4011 Lana Tier'], administrative_area: 'CA', locality: 'Fremont', postal_code: '94536', region_code: 'US')
      )
    end

    context 'with a second street line' do
      before { address.street2 = 'Suite 1' }

      it { expect(address.to_postal_address[:address_lines]).to(eq(['4011 Lana Tier', 'Suite 1'])) }
    end
  end

  describe '#to_transponder_graphql_input' do
    it { expect(address.to_transponder_graphql_input[:country]).to(eq({ alpha3: 'USA' })) }
    it { expect(address.to_transponder_graphql_input[:regionAbbreviation]).to(eq('CA')) }
  end

  describe '#types' do
    it { expect(address.types).to(eq([])) }

    context 'when the street names an aircraft hangar' do
      before { address.assign_attributes(street: '1 Hangar Way', types: ['restaurant']) }

      it { expect(address.types).to(eq(['airport', 'restaurant'])) }
    end

    context 'when the ZIP code is on a military base' do
      before { address.zip_code = '10997' }

      it { expect(address.types).to(eq(['military_site'])) }
    end
  end

  describe 'auditing' do
    let!(:shipment) { create(:shipment, shipper_address: address) }

    before { address.update!(latitude: 1, name: 'Acme Freight') }

    it { expect(address.audits.sole.audited_changes.keys).to(eq(['name'])) }
    it { expect(address.audits.sole.associated).to(eq(shipment)) }
    it { expect(shipment.own_and_associated_audits).to(include(address.audits.sole)) }
  end

  describe 'validations' do
    before { address.validate }

    it { expect(address.errors).to(be_empty) }

    context 'when the country is blank' do
      let(:address) { build(:address, country_alpha2: nil) }

      it { expect(address.country_alpha2).to(eq('US')) }
    end

    context 'when the region code is unknown' do
      let(:address) { build(:address, region_iso31662: 'US-ZZ') }

      it { expect(address.errors.of_kind?(:region, :invalid)).to(be(true)) }
    end

    context 'when the region is not within the country' do
      let(:address) { build(:address, country_alpha2: 'CA') }

      it { expect(address.errors[:region]).to(include("isn't within Canada")) }
    end

    context 'when the zip code does not match the country format' do
      let(:address) { build(:address, zip_code: '9453') }

      it { expect(address.errors[:zip_code]).to(be_present) }

      context 'when saved before the format applied' do
        let(:address) do
          create(:address).tap do |address|
            address.update_column(:zip_code, '9453') # rubocop:disable Rails/SkipsModelValidations
            address.reload.name = 'Acme'
          end
        end

        it { expect(address.errors[:zip_code]).to(be_empty) }
      end

      context 'when saved before the format applied and the country changes' do
        let(:address) do
          create(:address).tap do |address|
            address.update_column(:zip_code, '9453') # rubocop:disable Rails/SkipsModelValidations
            address.reload.assign_attributes(country_alpha2: 'MX', region_iso31662: nil)
          end
        end

        it { expect(address.errors[:zip_code]).to(be_present) }
      end
    end

    context 'when the zip code is blank' do
      let(:address) { build(:address, zip_code: '') }

      it { expect(address.errors.of_kind?(:zip_code, :blank)).to(be(true)) }

      context 'when the country has no postal codes' do
        let(:address) do
          build(:address, zip_code: '').tap do |address|
            allow(address).to(receive(:country).and_return(Grid::ORM::Country.new(alpha2: 'HK', postal_code: false)))
          end
        end

        it { expect(address.errors[:zip_code]).to(be_empty) }
      end
    end
  end
end
