require 'rails_helper'

RSpec.describe(Tools::FetchRates) do
  subject(:tool_response) { described_class.call(server_context: { authorizable: }, shipment_load_id: shipment.load_id.to_s) }

  let(:authorizable) { create(:root_broker_user) }
  let(:broker_carrier) { create(:broker_carrier) }
  let(:data) { JSON.parse(tool_response.content.first[:text]).dig('data', 'fetchRates') }
  let(:new_rate) { create(:rate, broker_carrier:, cost_cents: 12_345, cost_currency: 'USD', shipment:) }
  let(:shipment) { create(:shipment, broker_carrier:) }

  before do
    allow_any_instance_of(BrokerCustomer).to(receive(:carrier_charge_calculator).and_return(Money.new(15_000, 'USD')))
    allow_any_instance_of(Shipment).to(receive(:valid_broker_carriers_for_quotation).and_return(BrokerCarrier.where(id: broker_carrier.id)))
    allow(Shipment::RatesService).to(receive(:call).and_return([new_rate]))
  end

  it { is_expected.not_to(be_error) }
  it { expect(data['rates']).to(contain_exactly(include('chargeCents' => 15_000, 'costCents' => 12_345))) }
  it { expect(data.dig('shipment', 'loadId')).to(eq(shipment.load_id)) }
  it { expect(described_class.to_h).to(include(annotations: include(destructiveHint: true, readOnlyHint: false), name: 'fetch_rates')) }

  context 'when the user is a customer' do
    let(:authorizable) { create(:customer_user, companyable: shipment.broker_customer) }

    it { expect(data['rates']).to(contain_exactly(include('chargeCents' => 15_000))) }
    it { expect(data['rates'].first).not_to(include('costCents')) }
  end
end
