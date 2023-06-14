# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(Address::SmartyStreetsVerifyService) do
  let(:address_key) { "4011 Lana Tier, Fremont, California, 94536"}
  let(:mock_address_service) { instance_double(MainStreet::AddressVerifier) }

  describe '#call' do
    subject { described_class.new(address_key:).call }

    context 'when address is valid' do
      let(:mock_data) { double('MockResult', data: { address_data: {} })}

      before do
        expect(MainStreet::AddressVerifier).to receive(:new).with(address_key).and_return(mock_address_service)
        expect(mock_address_service).to receive(:result).and_return(mock_data)
      end

      it 'returns data from MainStreet' do
        expect(subject).to eq({ address_data: {} })
      end
    end

    context 'when address is invalid' do
      let(:mock_data) do
        double(
          'MockResult',
          data: [
            'errors',
            [{ 'message' => "Invalid Address"}]
          ]
        )
      end

      before do
        expect(MainStreet::AddressVerifier).to receive(:new).with(address_key).and_return(mock_address_service)
        expect(mock_address_service).to receive(:result).and_return(mock_data)
      end

      it 'returns null and reports to Honeybadger' do
        expect(Honeybadger).to receive(:notify).with(error_message: 'Invalid Address')

        expect(subject).to be_nil
      end
    end
  end
end
