require 'rails_helper'

RSpec.describe(Address::GooglePlacesVerifyService) do
  let(:address_key) { "4011 Lana Tier, Fremont, California, 94536" }
  let(:street) { '4011 Lana Tier' }
  let(:mock_address_service) { instance_double(GooglePlaces::Client) }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('GOOGLE_API_KEY').and_return('mock_api_key')
    allow(ENV).to receive(:fetch).with('GOOGLE_API_KEY').and_return('mock_api_key')
  end

  describe '#call' do
    subject(:call) { described_class.new(address_key:, street:).call }

    before do
      allow(GooglePlaces::Client).to receive(:new).with('mock_api_key').and_return(mock_address_service)
      allow(mock_address_service).to receive(:spots_by_query).with(address_key).and_return(mock_data)
    end

    context 'when address is valid' do
      let(:mock_result) { instance_double(GooglePlaces::Spot, formatted_address: address_key) }
      let(:mock_data) { [ mock_result ] }

      before { allow(mock_result).to receive(:is_a?).with(GooglePlaces::Spot).and_return(true) }

      it { is_expected.to eq(mock_data.first) }

      context 'when result formatted address doesnt contain street number' do
        let(:mock_result) { instance_double(GooglePlaces::Spot, formatted_address: 'No Street Number Lana Tier Fremont, California 94536') }

        it { is_expected.to be_nil }
      end
    end

    context 'when address result is not a GooglePlaces::Spot instance' do
      let(:mock_data) { [ Object.new ] }

      it { is_expected.to be_nil }
    end
  end
end
