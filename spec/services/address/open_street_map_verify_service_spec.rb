# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(Address::OpenStreetMapVerifyService) do
  let(:address_key) { "4011 Lana Tier, Fremont, California, 94536"}
  let(:street) { '4011 Lana Tier' }
  let(:country) { create(:country) }
  let(:mock_address_service) { instance_double(OpenStreetMap::Client) }
  let(:query_string) { "#{address_key}, #{country.name}"}

  describe '#call' do
    subject { described_class.new(address_key:, country:, street:).call }

    before do
      expect(OpenStreetMap::Client).to receive(:new).and_return(mock_address_service)
      expect(mock_address_service).to receive(:search).with(
        q: query_string,
        format: 'json',
        addressdetails: '1',
        accept_language: 'en'
      ).and_return(mock_data)
    end

    context 'when address is valid' do
      let(:mock_data) do
       [{ 'display_name' => '4011 Lana Tier Fremont, California 94536' }]
      end

      it 'returns data from Open Street Map' do
        expect(subject).to eq(mock_data.first)
      end
    end

    context 'when address result is not a hash' do
      let(:mock_data) do
        ['Invalid Address']
       end
 
      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when address result display name doesnt contain street number' do
      let(:mock_data) do
       [{ 'display_name' => 'No Street Number Lana Tier Fremont, California 94536' }]
       end
 
      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
  end
end
