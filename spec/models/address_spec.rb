# == Schema Information
#
# Table name: addresses
#
# @!attribute id
#   @return []
# @!attribute city
#   @return [String]
# @!attribute country_alpha2
#   @return [String]
# @!attribute google_places_spot_cached
#   @return [String]
# @!attribute google_places_spot_updated_at
#   @return [Time]
# @!attribute latitude
#   @return []
# @!attribute longitude
#   @return []
# @!attribute open_street_map_result_cached
#   @return [String]
# @!attribute open_street_map_result_updated_at
#   @return [Time]
# @!attribute original_attributes
#   @return [String]
# @!attribute ref
#   @return [String]
# @!attribute region_iso31662
#   @return [String]
# @!attribute smarty_streets_result_updated_at
#   @return [Time]
# @!attribute street
#   @return [String]
# @!attribute street2
#   @return [String]
# @!attribute time_zone_name
#   @return [String]
# @!attribute verification_info
#   @return [String]
# @!attribute zip_code
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute standardized_address_id
#   @return []
#
# Indexes
#
#  index_addresses_on_country_alpha2           (country_alpha2)
#  index_addresses_on_region_iso31662          (region_iso31662)
#  index_addresses_on_standardized_address_id  (standardized_address_id)
#
# Foreign Keys
#
#  fk_rails_...  (standardized_address_id => standardized_addresses.id)
#
require 'rails_helper'

RSpec.describe(Address) do
  let(:address) { build(:address, city: 'Fremont', street: '4011 Lana Tier', zip_code: '94536') }

  describe '.ransackable_associations' do
    it { expect(described_class.ransackable_associations).to(be_empty) }
  end

  describe '.ransackable_attributes' do
    it { expect(described_class.ransackable_attributes).to(include('country_alpha2', 'region_iso31662')) }
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

  describe '#region' do
    it { expect(address.region).to(equal(Transponder::ORM::Region.find('US-CA'))) }
  end

  describe '#to_freight_kit_shipping_address' do
    let(:location) { address.to_freight_kit_shipping_address }

    it { expect(location.country.code(:alpha2).value).to(eq('US')) }
    it { expect(location.province).to(eq('CA')) }
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
