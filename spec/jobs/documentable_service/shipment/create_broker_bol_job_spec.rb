require 'rails_helper'

RSpec.describe(DocumentableService::Shipment::CreateBrokerBOLJob) do
  describe '.render' do
    let(:shipment) { build(:shipment) }

    before { allow(PDFService::Renderer).to(receive(:call).with('shipments/documents_bol', locals: { shipment: }).and_return('%PDF-1.7')) }

    it { expect(described_class.render(shipment)).to(eq('%PDF-1.7')) }
  end
end
