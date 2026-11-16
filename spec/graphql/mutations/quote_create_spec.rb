require 'rails_helper'

RSpec.describe(Mutations::QuoteCreate) do
  subject(:result) { LiftoffSchema.execute(query, context: { authorizable: }, variables:).to_h }

  let(:authorizable) { create(:customer_user, companyable: broker_customer) }
  let(:accessorial) { create(:accessorial, freight_kit_code: 'liftgate_delivery') }
  let(:accessorial_codes) { ['liftgate_delivery'] }
  let(:broker_accessorial) { create(:broker_accessorial, accessorial:, broker_customer:) }
  let(:broker_carrier) { create(:broker_carrier, carrier: create(:carrier, scac: 'ABCD')) }
  let(:broker_customer) { create(:broker_customer) }
  let(:data) { result.dig('data', 'quoteCreate') }
  let(:new_rate) { build(:rate, broker_carrier:, cost_cents: 12_345, cost_currency: 'USD') }
  let(:query) do
    <<~GRAPHQL
      mutation($input: QuoteCreateInput!) {
        quoteCreate(input: $input) {
          rates { #{rate_fields} }
          shipment { loadId receiverAddress { city street } shipperAddress { city zipCode } }
        }
      }
    GRAPHQL
  end
  let(:rate_fields) { 'chargeCents scac' }
  let(:shipment) { Shipment.last }
  let(:variables) do
    {
      input: {
        accessorialCodes: accessorial_codes,
        packages: [{ quantity: 2, weight: 500 }],
        pickupOn: '2026-11-03',
        receiverAddress: { city: 'Fremont', regionIso31662: 'US_CA', street: '4011 Lana Tier', zipCode: '94536' },
        shipperAddress: { city: 'Austin', regionIso31662: 'US_TX', zipCode: '78701' }
      }
    }
  end

  before do
    broker_accessorial
    create(:packaging, freight_kit_type: 'pallet')
    allow_any_instance_of(BrokerCustomer).to(receive(:carrier_charge_calculator).and_return(Money.new(15_000, 'USD')))
    allow_any_instance_of(Shipment).to(receive(:valid_broker_carriers_for_quotation).and_return(BrokerCarrier.where(id: broker_carrier.id)))
    allow(Shipment::RatesService).to(receive(:call).and_return([new_rate]))
  end

  it { expect { result }.to(change(Shipment, :count).by(1)) }
  it { expect(data['rates']).to(eq([{ 'chargeCents' => 15_000, 'scac' => 'ABCD' }])) }
  it { expect(data['shipment']['receiverAddress']).to(eq('city' => 'Fremont', 'street' => '4011 Lana Tier')) }
  it { expect(data['shipment']['shipperAddress']).to(eq('city' => 'Austin', 'zipCode' => '78701')) }

  context 'with the created shipment' do
    before { result }

    it { expect(shipment).to(have_attributes(broker_customer:, created_by: authorizable, pickup_on: Date.new(2026, 11, 3))) }
    it { expect(shipment).to(be_quote_only) }
    it { expect(shipment.items.pluck(:quantity, :weight)).to(eq([[2, 500]])) }
    it { expect(shipment.shipment_broker_accessorials.pluck(:broker_accessorial_id)).to(eq([broker_accessorial.id])) }
  end

  context 'with an accessorial the customer is not offered' do
    let(:accessorial_codes) { ['liftgate_delivery', 'inside_delivery', 'inside_delivery'] }
    let(:error) { result['errors'].sole }

    it { expect { result }.not_to(change(Shipment, :count)) }
    it { expect(error['extensions']).to(eq('accessorialCodes' => ['inside_delivery'], 'code' => 'UNSERVICEABLE_ACCESSORIALS')) }
    it { expect(error['message']).to(eq('Accessorials not offered: inside_delivery')) }
  end

  context 'with a blanket accessorial' do
    let(:broker_accessorial) { create(:broker_accessorial, accessorial:, broker_customer: nil) }

    before { result }

    it { expect(result['errors']).to(be_nil) }
    it { expect(shipment.shipment_broker_accessorials.pluck(:broker_accessorial_id)).to(include(broker_accessorial.id)) }
  end

  context 'when the user is a broker' do
    let(:authorizable) { create(:broker_user).tap { |broker_user| broker_user.add_role(:root) } }

    it { expect(result['errors'].first['extensions']).to(eq('code' => 'NOT_FOUND')) }

    context 'with a customer' do
      let(:rate_fields) { 'chargeCents costCents scac' }
      let(:variables) { { input: super()[:input].merge(customerId: broker_customer.id.to_s) } }

      it { expect(data['rates']).to(eq([{ 'chargeCents' => 15_000, 'costCents' => 12_345, 'scac' => 'ABCD' }])) }
    end
  end

  context 'when a customer asks for costs' do
    let(:rate_fields) { 'costCents' }

    it { expect(result['errors'].pluck('message')).to(include("Field 'costCents' doesn't exist on type 'Rate'")) }
    it { expect { result }.not_to(change(Shipment, :count)) }
  end

  context 'when a package exceeds the unit limit' do
    let(:variables) { { input: super()[:input].merge(packages: [{ quantity: 1_001, weight: 500 }]) } }

    it { expect(result['errors'].first['message']).to(include('quantity must be less than or equal to 1000')) }
    it { expect { result }.not_to(change(Shipment, :count)) }
  end

  context 'when the packages together exceed the unit limit' do
    let(:variables) { { input: super()[:input].merge(packages: [{ quantity: 600, weight: 500 }, { quantity: 401, weight: 500 }]) } }

    it { expect(result['errors'].first['extensions']).to(eq('code' => 'TOO_MANY_UNITS')) }
    it { expect { result }.not_to(change(Shipment, :count)) }
  end

  context 'without packages' do
    let(:variables) { { input: super()[:input].merge(packages: []) } }

    it { expect(result['errors'].first['message']).to(include('packages is too short')) }
  end

  context 'when the user is a carrier' do
    let(:authorizable) { create(:user, companyable: broker_carrier.carrier) }
    let(:rate_fields) { 'scac' }

    it { expect(result['errors'].first['extensions']).to(eq('code' => 'UNAUTHORIZED')) }
    it { expect { result }.not_to(change(Shipment, :count)) }
  end

  context 'when the shipment is invalid' do
    before { allow_any_instance_of(Shipment).to(receive(:save).and_return(false)) }

    it { expect(result['errors']).to(be_present) }
    it { expect(data).to(be_nil) }
  end
end
