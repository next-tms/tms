# == Schema Information
#
# Table name: broker_countries
#
# @!attribute id
#   @return []
# @!attribute country_alpha2
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
#
# Indexes
#
#  index_broker_countries_on_country_alpha2  (country_alpha2) UNIQUE
#
# @!attribute id
#   @return []
# @!attribute country_alpha2
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
#
# Indexes
#
#  index_broker_countries_on_country_alpha2  (country_alpha2) UNIQUE
#
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

  describe '#create_region_areas' do
    it { expect { described_class.create!(country_alpha2: 'CA') }.to(change(Area, :count).by(2)) }

    it do
      expect { described_class.create!(country_alpha2: 'CA') }.to(change do
        Area.pluck(:name).sort
      end.to(['British Columbia, CA', 'Ontario, CA']))
    end

    context 'when the region areas exist' do
      before { Area.find_or_create_by_region!(Transponder::ORM::Region.find('CA-ON')) }

      it { expect { described_class.create!(country_alpha2: 'CA') }.to(change(Area, :count).by(1)) }
    end
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
