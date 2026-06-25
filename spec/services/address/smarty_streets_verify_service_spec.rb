require 'rails_helper'

RSpec.describe(Address::SmartyStreetsVerifyService) do
  let(:address_key) { "4011 Lana Tier, Fremont, California, 94536" }
  let(:mock_address_service) { instance_double(MainStreet::AddressVerifier) }

  describe '#call' do
    subject(:call) { described_class.new(address_key:).call }

    before do
      allow(MainStreet::AddressVerifier).to receive(:new).with(address_key).and_return(mock_address_service)
      allow(mock_address_service).to receive(:result).and_return(mock_data)
    end

    context 'when address is valid' do
      let(:mock_data) { Struct.new(:data).new({ address_data: {} }) }

      it { is_expected.to eq({ address_data: {} }) }
    end

    context 'when address is invalid' do
      let(:mock_data) { Struct.new(:data).new([ 'errors', [ { 'message' => 'Invalid Address' } ] ]) }

      before { allow(Sentry).to receive(:capture_message) }

      it { is_expected.to be_nil }

      it 'notifies Sentry' do
        call
        expect(Sentry).to have_received(:capture_message).with('Invalid Address')
      end
    end
  end
end
