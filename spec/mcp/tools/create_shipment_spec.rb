require 'rails_helper'

RSpec.describe(Tools::CreateShipment) do
  subject(:tool_response) { described_class.call(**arguments, server_context: { authorizable: }) }

  let(:arguments) do
    {
      customer_reference: '1001',
      pickup_on: '2026-11-03',
      rate_id: rate.id.to_s,
      receiver: { contact_name: 'Rita Receiver', name: 'Receiver Co' },
      shipper_reference: '2002'
    }
  end
  let(:authorizable) { create(:customer_user, companyable: broker_customer) }
  let(:broker_carrier) { create(:broker_carrier) }
  let(:broker_customer) { create(:broker_customer) }
  let(:data) { JSON.parse(tool_response.content.first[:text]).dig('data', 'shipmentCreate', 'shipment') }
  let(:rate) do
    create(
      :rate,
      broker_carrier:,
      broker_customer:,
      cost_cents: 12_345,
      cost_currency: 'USD',
      expires_at: 1.day.from_now,
      shipment:,
      shipment_fingerprint: shipment.fingerprint,
      transit_days: 2
    )
  end
  let(:shipment) do
    create(:shipment, booked_at: nil, broker_customer:, delivered_at: nil, dispatched_at: nil, picked_up_at: nil, quote_only: true)
  end

  before do
    allow_any_instance_of(BrokerCustomer).to(receive(:carrier_charge_calculator).and_return(Money.new(15_000, 'USD')))
    allow_any_instance_of(Shipment).to(receive(:valid_broker_carriers_for_quotation).and_return(BrokerCarrier.where(id: broker_carrier.id)))
  end

  it { is_expected.not_to(be_error) }
  it { expect(data).to(include('customerReference' => '1001', 'loadId' => shipment.load_id, 'receiverContactName' => 'Rita Receiver')) }
  it { expect(data).not_to(include('carrierCostCents', 'totalCostCents')) }
  it { expect(described_class.to_h).to(include(annotations: include(destructiveHint: true, readOnlyHint: false), name: 'create_shipment')) }

  context 'when booked' do
    before { tool_response }

    it { expect(shipment.reload).to(have_attributes(applied_rate: rate, quote_only: false, shipper_reference: '2002')) }
  end
end
