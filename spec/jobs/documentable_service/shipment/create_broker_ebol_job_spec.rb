require 'rails_helper'

RSpec.describe(DocumentableService::Shipment::CreateBrokerEBOLJob) do
  let(:document) { { version: EBOL::VERSION } }
  let(:shipment) { create(:shipment) }
  let(:valid) { true }

  before do
    allow(DocumentableService).to(receive(:call))
    allow(EBOL).to(receive(:valid?).with(document).and_return(valid))
    allow(EBOL::Exporter).to(receive(:call).with(shipment).and_return(document))
  end

  describe '.render' do
    subject { described_class.render(shipment) }

    it { is_expected.to(eq(document.to_json)) }

    context 'when the eBOL is invalid' do
      let(:valid) { false }

      it { is_expected.to(be_nil) }
    end
  end

  describe '#perform' do
    before do
      allow(shipment).to(receive(:broadcast_new_document_generated))
      described_class.perform_now(shipment)
    end

    it { expect(shipment.broker_ebol).to(be_attached) }
    it { expect(shipment.broker_ebol.content_type).to(eq('application/vnd.nmfta.ebol+json')) }
    it { expect(shipment.broker_ebol.download).to(eq(document.to_json)) }
    it { expect(shipment.broker_ebol.filename.to_s).to(eq("#{shipment.load_id}.ebol.json")) }
    it { expect(shipment).to(have_received(:broadcast_new_document_generated).with(:broker_ebol)) }

    context 'when the eBOL is invalid' do
      let(:valid) { false }

      it { expect(shipment.broker_ebol).not_to(be_attached) }
      it { expect(shipment).not_to(have_received(:broadcast_new_document_generated)) }
    end
  end
end
