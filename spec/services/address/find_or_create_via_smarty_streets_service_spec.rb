# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(Address::FindOrCreateViaSmartyStreetsService) do
  let(:address_key) { "4011 Lana Tier, Fremont, CA 94536" }
  let(:region) { create(:region, name: 'California', abbreviation: 'CA') }
  let(:street) { '4011 Lana Tier' }
  let(:city) { 'Fremont' }
  let(:zip_code) { '94536' }

  describe '#call' do
    subject(:call) { described_class.new(street:, city:, zip_code:, region_id: region.id).call }

    context 'when standardized address record is already present' do
      let!(:standardized_address) { create(:standardized_address, key: address_key, region:, country: region.country) }

      it { is_expected.to eq(standardized_address) }
    end

    context 'when standardized address record doesnt exists' do
      let(:mock_service) { instance_double(Address::SmartyStreetsVerifyService) }

      before do
        allow(Address::SmartyStreetsVerifyService).to receive(:new).with(address_key:).and_return(mock_service)
        allow(mock_service).to receive(:call).and_return(mock_data)
      end

      context 'when verify service returns nil' do
        let(:mock_data) { nil }

        it { is_expected.to be_nil }
      end

      context 'when verify service returns address data' do
        let(:mock_data) { { address_data: {} } }

        it { expect { call }.to change(StandardizedAddress, :count).by(1) }
      end
    end
  end
end
