require 'rails_helper'

RSpec.describe(Mutations::FetchRates) do
  subject(:result) { TMSSchema.execute(query, context: { authorizable: }, variables:).to_h }

  let(:authorizable) { create(:broker_user).tap { |broker_user| broker_user.add_role(:dispatch) } }
  let(:broker_carrier) { create(:broker_carrier) }
  let(:new_rate) { build(:rate, broker_carrier:, cost_cents: 12_345, cost_currency: 'USD', shipment:) }
  let(:other_broker_carrier) { create(:broker_carrier) }
  let(:query) do
    <<~GRAPHQL
      mutation($carrierAccountId: ID, $loadId: ID!) {
        fetchRates(input: { carrierAccountId: $carrierAccountId, shipmentLoadId: $loadId }) {
          rates { #{rate_fields} }
        }
      }
    GRAPHQL
  end
  let(:rate_fields) { 'carrierName chargeCents costCents' }
  let(:rates) { result.dig('data', 'fetchRates', 'rates') }
  let(:shipment) { create(:shipment, broker_carrier:) }
  let(:variables) { { loadId: shipment.load_id.to_s } }

  before do
    allow_any_instance_of(BrokerCustomer).to(receive(:carrier_charge_calculator).and_return(Money.new(15_000, 'USD')))
    allow_any_instance_of(Shipment).to(receive(:valid_broker_carriers_for_quotation).and_return(BrokerCarrier.where(id: broker_carrier.id)))
    allow(Shipment::RatesService).to(receive(:call).and_return([new_rate]))
  end

  it { expect(rates).to(eq([{ 'carrierName' => broker_carrier.carrier.name, 'chargeCents' => 15_000, 'costCents' => 12_345 }])) }

  it do
    result

    expect(Shipment::RatesService).to(have_received(:call).with(broker_carrier, shipment, declared_freight_classes: false, save: true))
  end

  context 'when a carrier account outside the quotable list is requested' do
    let(:variables) { { carrierAccountId: other_broker_carrier.id.to_s, loadId: shipment.load_id.to_s } }

    it { expect(rates).to(be_empty) }
  end

  context 'when a rate already exists for the shipment fingerprint' do
    let!(:existing_rate) do
      create(
        :rate,
        broker_carrier:,
        cost_cents: 9_000,
        declared_freight_classes: false,
        expires_at: 1.day.from_now,
        shipment:,
        shipment_fingerprint: shipment.fingerprint
      )
    end

    it { expect(rates.pluck('costCents')).to(eq([existing_rate.cost_cents])) }

    it do
      result

      expect(Shipment::RatesService).not_to(have_received(:call))
    end

    context 'when the existing rate has expired' do
      before { existing_rate.update_column(:expires_at, 1.minute.ago) } # rubocop:disable Rails/SkipsModelValidations

      it { expect(rates.pluck('costCents')).to(eq([new_rate.cost_cents])) }
    end
  end

  context 'when declaredFreightClasses is null' do
    let(:query) do
      <<~GRAPHQL
        mutation($loadId: ID!) {
          fetchRates(input: { declaredFreightClasses: null, shipmentLoadId: $loadId }) { rates { costCents } }
        }
      GRAPHQL
    end

    it { expect(result['errors']).to(be_nil) }

    it do
      result

      expect(Shipment::RatesService).to(have_received(:call).with(broker_carrier, shipment, declared_freight_classes: false, save: true))
    end
  end

  context 'when the rate has no cost' do
    let(:new_rate) { build(:rate, broker_carrier:, cost_cents: 0, shipment:) }

    it { expect(rates).to(be_empty) }
  end

  context 'when the shipment does not exist' do
    let(:variables) { { loadId: '0' } }

    it { expect(result['errors'].first['extensions']).to(eq('code' => 'UNAUTHORIZED')) }
  end

  context 'when the user is a carrier' do
    let(:authorizable) { create(:user, companyable: broker_carrier.carrier) }
    let(:rate_fields) { 'carrierName' }

    it { expect(result.dig('data', 'fetchRates')).to(be_nil) }
    it { expect(result['errors'].first['extensions']).to(eq('code' => 'UNAUTHORIZED')) }
  end

  context 'when the user is a customer' do
    let(:authorizable) { create(:customer_user, companyable: shipment.broker_customer) }

    it { expect(result['errors'].pluck('message')).to(include("Field 'costCents' doesn't exist on type 'Rate'")) }

    context 'without hidden fields' do
      let(:rate_fields) { 'carrierName chargeCents' }

      it { expect(rates).to(eq([{ 'carrierName' => broker_carrier.carrier.name, 'chargeCents' => 15_000 }])) }
    end

    context 'when the charge is not above the cost' do
      let(:rate_fields) { 'carrierName chargeCents' }

      before { allow_any_instance_of(BrokerCustomer).to(receive(:carrier_charge_calculator).and_return(Money.new(12_345, 'USD'))) }

      it { expect(rates).to(be_empty) }
    end
  end
end
