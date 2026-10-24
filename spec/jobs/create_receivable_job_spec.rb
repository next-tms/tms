require 'rails_helper'

RSpec.describe(CreateReceivableJob) do
  describe '#perform' do
    let(:receivable) { instance_double(Receivable, save: true, total: Money.new(100), update: true) }
    let(:shipment) { create(:shipment) }

    before do
      allow(shipment).to(receive_messages(lock!: shipment, receivable?: true, reload: shipment))
      allow(Receivable).to(receive(:build_from_shipment).with(shipment).and_return(receivable))
      allow(Accounting).to(receive(:connected?).and_return(false))
    end

    context 'when the automatically_authorize_receivables setting is true' do
      before do
        create(:setting, key: 'automatically_authorize_receivables', value: true)
        described_class.perform_now(shipment)
      end

      it { expect(receivable).to(have_received(:update).with(authorized_at: anything)) }
    end

    context 'when the automatically_authorize_receivables setting is missing' do
      before { described_class.perform_now(shipment) }

      it { expect(receivable).not_to(have_received(:update)) }
    end
  end
end
