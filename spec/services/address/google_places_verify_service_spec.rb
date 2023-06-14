# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(Address::GooglePlacesVerifyService) do
  let(:address_key) { "4011 Lana Tier, Fremont, California, 94536"}
  let(:street) { '4011 Lana Tier' }
  let(:mock_address_service) { instance_double(GooglePlaces::Client) }

  before do
    allow(ENV).to receive(:fetch).with('GOOGLE_API_KEY').and_return('mock_api_key')
  end

  describe '#call' do
    subject { described_class.new(address_key:, street:).call }

    before do
      expect(GooglePlaces::Client).to receive(:new).with('mock_api_key').and_return(mock_address_service)
      expect(mock_address_service).to receive(:spots_by_query).with(address_key).and_return(mock_data)
    end

    context 'when address is valid' do
      let(:mock_result) { instance_double(GooglePlaces::Spot, formatted_address: address_key) }
      let(:mock_data) { [mock_result] }

      before do
        expect(mock_result).to receive(:is_a?).with(GooglePlaces::Spot).and_return(true)
      end

      it 'returns data from Open Street Map' do
        expect(subject).to eq(mock_data.first)
      end

      context 'and result formatted address doesnt contain street number' do
        let(:mock_result) { instance_double(GooglePlaces::Spot, formatted_address: 'No Street Number Lana Tier Fremont, California 94536') }
   
        it 'returns nil' do
          expect(subject).to be_nil
        end
      end
    end

    context 'when address result is not a GooglePlaces::Spot instance' do
      let(:mock_data) do
        [double('MockResult')]
      end
 
      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
  end
end
