require 'rails_helper'

RSpec.describe(Tools::GetShipment) do
  subject(:tool_response) { described_class.call(id: shipment.load_id.to_s, server_context: { authorizable: }) }

  let(:authorizable) { create(:root_broker_user) }
  let(:data) { JSON.parse(tool_response.content.first[:text]).dig('data', 'shipment') }
  let(:shipment) { create(:shipment, broker_carrier: create(:broker_carrier)) }

  it { is_expected.not_to(be_error) }
  it { expect(data['id']).to(eq(shipment.load_id.to_s)) }
  it { expect(data).to(include('carrierCostCents', 'items', 'receiverAddress')) }
  it { expect(described_class.to_h).to(include(annotations: include(readOnlyHint: true), name: 'get_shipment')) }

  context 'when the user is a customer' do
    let(:authorizable) { create(:customer_user, companyable: shipment.broker_customer) }

    it { expect(data['id']).to(eq(shipment.load_id.to_s)) }
    it { expect(data).not_to(include('carrierCostCents', 'carrierCostCurrency', 'totalCostCents', 'totalCostCurrency')) }
  end

  context 'when the user is a carrier' do
    let(:authorizable) { create(:user, companyable: shipment.broker_carrier.carrier) }

    it { expect(data['id']).to(eq(shipment.load_id.to_s)) }
    it { expect(data).not_to(include('totalChargesCents', 'totalChargesCurrency')) }
  end
end
