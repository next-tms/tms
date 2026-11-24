require 'rails_helper'

RSpec.describe(Shipment::CreateRatesJob) do
  describe 'CONCURRENCY' do
    it { expect(described_class::CONCURRENCY).to(eq(8)) }
  end

  describe '#perform' do
    let(:broker_carriers) { create_list(:broker_carrier, 2) }
    let(:channel) { "rates_channel_#{shipment.id}" }
    let(:fingerprint) { shipment.fingerprint }
    let(:latch) { Concurrent::CountDownLatch.new(broker_carriers.size) }
    let(:shipment) { create(:shipment) }
    let(:waits) { Concurrent::Array.new }

    before do
      allow(ActionCable.server).to(receive(:broadcast))
      allow(ApplicationController).to(receive(:render).and_return('<div></div>'))
      allow(Shipment::RatesService).to(receive(:call)) do
        latch.count_down
        waits << latch.wait(1)
        []
      end

      described_class.perform_now(shipment, fingerprint, :broker, false, broker_carriers.map(&:id))
    end

    it { expect(ActionCable.server).to(have_received(:broadcast).with(channel, hash_including(:html)).twice) }
    it { expect(ActionCable.server).to(have_received(:broadcast).with(channel, { finished: true })) }
    it { expect(waits).to(eq([true, true])) }

    context 'with a stale fingerprint' do
      let(:fingerprint) { 'stale' }

      it { expect(ActionCable.server).not_to(have_received(:broadcast).with(channel, anything)) }
    end
  end
end
