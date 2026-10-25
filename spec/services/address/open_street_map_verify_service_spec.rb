require 'rails_helper'

RSpec.describe(Address::OpenStreetMapVerifyService) do
  let(:address_key) { "4011 Lana Tier, Fremont, California, 94536" }
  let(:street) { '4011 Lana Tier' }
  let(:country) { Transponder::ORM::Country.find('US') }
  let(:mock_address_service) { instance_double(OpenStreetMap::Client) }
  let(:query_string) { "#{address_key}, #{country.name}" }

  describe '#call' do
    subject(:call) { described_class.new(address_key:, country:, street:).call }

    before do
      allow(OpenStreetMap::Client).to receive(:new).and_return(mock_address_service)
      allow(mock_address_service).to receive(:search).with(
        q: query_string,
        format: 'json',
        addressdetails: '1',
        accept_language: 'en'
      ).and_return(mock_data)
    end

    context 'when address is valid' do
      let(:mock_data) { [ { 'display_name' => '4011 Lana Tier Fremont, California 94536' } ] }

      it { is_expected.to eq(mock_data.first) }
    end

    context 'when address result is not a hash' do
      let(:mock_data) { [ 'Invalid Address' ] }

      it { is_expected.to be_nil }
    end

    context 'when address result display name doesnt contain street number' do
      let(:mock_data) { [ { 'display_name' => 'No Street Number Lana Tier Fremont, California 94536' } ] }

      it { is_expected.to be_nil }
    end
  end
end
