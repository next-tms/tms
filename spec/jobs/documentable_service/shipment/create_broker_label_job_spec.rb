require 'rails_helper'

RSpec.describe(DocumentableService::Shipment::CreateBrokerLabelJob) do
  describe '.render' do
    let(:shipment) { create(:shipment, items: [build(:item, packaging: create(:packaging, name: 'pallet'), quantity: 2)]) }

    it { expect(described_class.render(shipment)).to(start_with('%PDF')) }
  end
end
