# frozen_string_literal: true

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

RSpec.describe(Country, type: :model) do
  describe '#valid_street?' do
    let(:alpha2_code) { 'CA' }
    let(:record) { create(:country, alpha2_code:) }

    it { expect(record.valid_street?(Faker::Alphanumeric.alphanumeric)).to eq(true) }

    context "when alpha2_code == 'US'" do
      let(:alpha2_code) { 'US' }

      it { expect(record.valid_street?('1-123 Main St Ste A')).to eq(false) }
      it { expect(record.valid_street?('1-123 Main St')).to eq(false) }
      it { expect(record.valid_street?('123 Main St Ste A')).to eq(true) }
      it { expect(record.valid_street?('123 Main St')).to eq(true) }
      it { expect(record.valid_street?('123-1 Main St Ste A')).to eq(false) }
      it { expect(record.valid_street?('123-1 Main St')).to eq(false) }
      it { expect(record.valid_street?('123A Main St Ste A')).to eq(true) }
      it { expect(record.valid_street?('123A Main St')).to eq(true) }
      it { expect(record.valid_street?('Main St Bldg 1200')).to eq(true) }
      it { expect(record.valid_street?('Main St Ste A')).to eq(true) }
      it { expect(record.valid_street?('Main St')).to eq(true) }
      it { expect(record.valid_street?('W229N1492 Westwood Dr Ste 2')).to eq(true) }
      it { expect(record.valid_street?('W229N1492 Westwood Dr')).to eq(true) }
    end
  end
end
