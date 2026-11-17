require 'rails_helper'

RSpec.describe(Tools::CreateQuote) do
  subject(:tool_response) { described_class.call(**arguments, server_context: { authorizable: }) }

  let(:arguments) do
    {
      packages: [{ quantity: 2, weight: 500 }],
      pickup_on: '2026-11-03',
      receiver_address: { city: 'Fremont', region_iso31662: 'US_CA', street: '4011 Lana Tier', zip_code: '94536' },
      shipper_address: { city: 'Austin', region_iso31662: 'US_TX', zip_code: '78701' }
    }
  end
  let(:authorizable) { create(:customer_user, companyable: broker_customer) }
  let(:broker_carrier) { create(:broker_carrier) }
  let(:broker_customer) { create(:broker_customer) }
  let(:data) { JSON.parse(tool_response.content.first[:text]).dig('data', 'quoteCreate') }
  let(:new_rate) { create(:rate, broker_carrier:, cost_cents: 12_345, cost_currency: 'USD') }

  before do
    create(:packaging, freight_kit_type: 'pallet')
    allow_any_instance_of(BrokerCustomer).to(receive(:carrier_charge_calculator).and_return(Money.new(15_000, 'USD')))
    allow_any_instance_of(Shipment).to(receive(:valid_broker_carriers_for_quotation).and_return(BrokerCarrier.where(id: broker_carrier.id)))
    allow(Shipment::RatesService).to(receive(:call).and_return([new_rate]))
  end

  it { is_expected.not_to(be_error) }
  it { expect { tool_response }.to(change(Shipment, :count).by(1)) }
  it { expect(data['rates']).to(contain_exactly(include('chargeCents' => 15_000))) }
  it { expect(data['rates'].first).not_to(include('costCents')) }
  it { expect(data.dig('shipment', 'receiverAddress')).to(include('city' => 'Fremont', 'street' => '4011 Lana Tier')) }
  it { expect(data['shipment']).not_to(include('carrierCostCents', 'totalCostCents')) }
  it { expect(described_class.to_h).to(include(annotations: include(destructiveHint: true, readOnlyHint: false), name: 'create_quote')) }
end
