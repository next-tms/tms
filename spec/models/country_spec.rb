# == Schema Information
#
# Table name: countries
#
# @!attribute id
#   @return []
# @!attribute alpha2_code
#   @return [String]
# @!attribute alpha3_code
#   @return [String]
# @!attribute name
#   @return [String]
# @!attribute un_code
#   @return [Integer]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
#
require 'rails_helper'

RSpec.describe(Country) do
  describe '#valid_street?' do
    let(:alpha2_code) { 'CA' }
    let(:record) { create(:country, alpha2_code:) }

    it { expect(record.valid_street?(Faker::Alphanumeric.alphanumeric)).to(be(true)) }

    context "when alpha2_code == 'US'" do
      let(:alpha2_code) { 'US' }

      it { expect(record.valid_street?('1-123 5th St Ste A')).to(be(false)) }
      it { expect(record.valid_street?('1-123 5th St')).to(be(false)) }
      it { expect(record.valid_street?('1-123 39th Avenue Dr Ste A')).to(be(false)) }
      it { expect(record.valid_street?('1-123 39th Avenue Dr')).to(be(false)) }
      it { expect(record.valid_street?('1-123 Johnson-Lewis Hwy Ste A')).to(be(false)) }
      it { expect(record.valid_street?('1-123 Johnson-Lewis Hwy')).to(be(false)) }
      it { expect(record.valid_street?('1-123 Main St Ste A')).to(be(false)) }
      it { expect(record.valid_street?('1-123 Main St')).to(be(false)) }
      it { expect(record.valid_street?('5th St Bldg 1200')).to(be(true)) }
      it { expect(record.valid_street?('5th St Ste A')).to(be(true)) }
      it { expect(record.valid_street?('5th St')).to(be(true)) }
      it { expect(record.valid_street?('39th Avenue Dr Bldg 1200')).to(be(true)) }
      it { expect(record.valid_street?('39th Avenue Dr Ste A')).to(be(true)) }
      it { expect(record.valid_street?('39th Avenue Dr')).to(be(true)) }
      it { expect(record.valid_street?('123 5th St Ste A')).to(be(true)) }
      it { expect(record.valid_street?('123 5th St')).to(be(true)) }
      it { expect(record.valid_street?('123 Johnson-Lewis Hwy Ste A')).to(be(true)) }
      it { expect(record.valid_street?('123 Johnson-Lewis Hwy')).to(be(true)) }
      it { expect(record.valid_street?('123 Main St Ste A')).to(be(true)) }
      it { expect(record.valid_street?('123 Main St')).to(be(true)) }
      it { expect(record.valid_street?('123-1 5th St Ste A')).to(be(false)) }
      it { expect(record.valid_street?('123-1 5th St')).to(be(false)) }
      it { expect(record.valid_street?('123-1 Johnson-Lewis Hwy Ste A')).to(be(false)) }
      it { expect(record.valid_street?('123-1 Johnson-Lewis Hwy')).to(be(false)) }
      it { expect(record.valid_street?('123-1 Main St Ste A')).to(be(false)) }
      it { expect(record.valid_street?('123-1 Main St')).to(be(false)) }
      it { expect(record.valid_street?('123A 5th St Ste A')).to(be(true)) }
      it { expect(record.valid_street?('123A 5th St')).to(be(true)) }
      it { expect(record.valid_street?('123A Johnson-Lewis Hwy Ste A')).to(be(true)) }
      it { expect(record.valid_street?('123A Johnson-Lewis Hwy')).to(be(true)) }
      it { expect(record.valid_street?('123A Main St Ste A')).to(be(true)) }
      it { expect(record.valid_street?('123A Main St')).to(be(true)) }
      it { expect(record.valid_street?('Johnson-Lewis Hwy Bldg 1200')).to(be(true)) }
      it { expect(record.valid_street?('Johnson-Lewis Hwy Ste A')).to(be(true)) }
      it { expect(record.valid_street?('Johnson-Lewis Hwy')).to(be(true)) }
      it { expect(record.valid_street?('Main St Bldg 1200')).to(be(true)) }
      it { expect(record.valid_street?('Main St Ste A')).to(be(true)) }
      it { expect(record.valid_street?('Main St')).to(be(true)) }
      it { expect(record.valid_street?('W229N1492 Westwood Dr Ste 2')).to(be(true)) }
      it { expect(record.valid_street?('W229N1492 Westwood Dr')).to(be(true)) }
      it { expect(record.valid_street?("1-123 O'Keefe Blvd Ste A")).to(be(false)) }
      it { expect(record.valid_street?("1-123 O'Keefe Blvd")).to(be(false)) }
      it { expect(record.valid_street?("123 O'Keefe Blvd Ste A")).to(be(true)) }
      it { expect(record.valid_street?("123-1 O'Keefe Blvd")).to(be(false)) }
      it { expect(record.valid_street?("123A O'Keefe Blvd Ste A")).to(be(true)) }
      it { expect(record.valid_street?("123A O'Keefe Blvd")).to(be(true)) }
      it { expect(record.valid_street?("O'Keefe Blvd Bldg 1200")).to(be(true)) }
      it { expect(record.valid_street?("O'Keefe Blvd Ste A")).to(be(true)) }
      it { expect(record.valid_street?("O'Keefe Blvd")).to(be(true)) }
    end
  end

  describe '.serviced' do
    let!(:serviced_country) { create(:country) }

    before do
      create(:country)
      BrokerCountry.create!(country: serviced_country)
    end

    it { expect(described_class.serviced).to(contain_exactly(serviced_country)) }
  end
end
