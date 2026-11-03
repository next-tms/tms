require 'rails_helper'

RSpec.describe(Mutations::ShipmentCreate) do
  subject(:result) { LiftoffSchema.execute(query, context: { authorizable: }, variables:).to_h }

  let(:authorizable) { create(:customer_user, companyable: broker_customer) }
  let(:broker_carrier) { create(:broker_carrier) }
  let(:broker_customer) { create(:broker_customer) }
  let(:charge) { Money.new(15_000, 'USD') }
  let(:query) do
    <<~GRAPHQL
      mutation($input: ShipmentCreateInput!) {
        shipmentCreate(input: $input) { shipment { loadId } }
      }
    GRAPHQL
  end
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
  let(:receiver_address) { create(:address, city: 'Fremont', region_iso31662: 'US-CA', street: nil, zip_code: '94536') }
  let(:shipment) do
    create(
      :shipment,
      booked_at: nil,
      broker_customer:,
      delivered_at: nil,
      dispatched_at: nil,
      picked_up_at: nil,
      quote_only: true,
      receiver_address:
    )
  end
  let(:variables) do
    {
      input: {
        bolNotes: 'Call ahead',
        customerReference: '1001',
        deliveryHoursEndAt: '2026-11-04T17:00:00-08:00',
        deliveryHoursStartAt: '2026-11-04T09:15:00-08:00',
        pickupHoursEndAt: '2026-11-03T16:30:00-08:00',
        pickupHoursStartAt: '2026-11-03T08:00:00-08:00',
        pickupOn: '2026-11-03',
        rateId: rate.id.to_s,
        receiver: {
          address: { city: 'Fremont', regionIso31662: 'US_CA', street: '4011 Lana Tier', zipCode: '94536' },
          contactEmail: 'receiver@example.com',
          contactName: 'Rita Receiver',
          contactPhone: '5105550100',
          name: 'Receiver Co'
        },
        shipper: { contactName: 'Sam Shipper', name: 'Shipper Co' },
        shipperReference: '2002'
      }
    }
  end

  before do
    allow_any_instance_of(BrokerCustomer).to(receive(:carrier_charge_calculator).and_return(charge))
    allow_any_instance_of(Shipment).to(receive(:valid_broker_carriers_for_quotation).and_return(BrokerCarrier.where(id: broker_carrier.id)))
  end

  it { expect(result.dig('data', 'shipmentCreate', 'shipment')).to(eq('loadId' => shipment.load_id)) }

  context 'with the booked shipment' do
    before { result }

    it do
      expect(shipment.reload).to(
        have_attributes(
          applied_rate: rate,
          bol_notes: 'Call ahead',
          customer_reference: '1001',
          delivery_hours_end_at: '5:00 PM',
          delivery_hours_start_at: '9:15 AM',
          pickup_hours_end_at: '4:30 PM',
          pickup_hours_start_at: '8:00 AM',
          pickup_on: Date.new(2026, 11, 3),
          quote_only: false,
          receiver_contact_email: 'receiver@example.com',
          receiver_contact_name: 'Rita Receiver',
          receiver_contact_phone: '+15105550100',
          receiver_name: 'Receiver Co',
          shipper_contact_name: 'Sam Shipper',
          shipper_name: 'Shipper Co',
          shipper_reference: '2002',
          updated_by: authorizable
        )
      )
    end

    it { expect(shipment.reload.booked_at).to(be_present) }
    it { expect(shipment.reload.quoted_delivery_by.to_date).to(eq(Date.new(2026, 11, 5))) }

    it do
      expect(shipment.reload.receiver_address).to(
        have_attributes(city: 'Fremont', id: receiver_address.id, street: '4011 Lana Tier', zip_code: '94536')
      )
    end
  end

  context 'when the rate does not exist' do
    let(:variables) { { input: { rateId: '0' } } }

    it { expect(result['errors'].first['extensions']).to(eq('code' => 'UNAUTHORIZED')) }
  end

  context 'when the rate has expired' do
    before { rate.update_column(:expires_at, 1.minute.ago) } # rubocop:disable Rails/SkipsModelValidations

    it { expect(result['errors'].first['extensions']).to(eq('code' => 'UNBOOKABLE_RATE')) }
  end

  context 'when the charge is not above the cost' do
    let(:charge) { Money.new(12_345, 'USD') }

    it { expect(result['errors'].first['extensions']).to(eq('code' => 'UNBOOKABLE_RATE')) }
  end

  context 'when the shipment is already booked' do
    let(:shipment) { create(:shipment, booked_at: 1.day.ago, broker_customer:) }

    it { expect(result['errors'].first['extensions']).to(eq('code' => 'BOOKED')) }
  end

  context 'when the details are invalid' do
    let(:variables) { { input: super()[:input].merge(pickupOn: '2000-01-01') } }

    before do
      allow_any_instance_of(Shipment).to(receive(:save).and_wrap_original do |method|
        method.receiver.pickup_on == Date.new(2000, 1, 1) ? false : method.call
      end)
      result
    end

    it { expect(result['errors']).to(be_present) }
    it { expect(shipment.reload).to(have_attributes(applied_rate: nil, booked_at: nil, quote_only: true)) }
  end

  context 'when the lane differs from the quote' do
    let(:variables) do
      input = super()[:input]

      { input: input.merge(receiver: input[:receiver].merge(address: input.dig(:receiver, :address).merge(zipCode: '94538'))) }
    end

    before { result }

    it { expect(result['errors'].first['extensions']).to(eq('code' => 'RATE_OUTDATED')) }
    it { expect(shipment.reload).to(have_attributes(applied_rate: nil, booked_at: nil, quote_only: true)) }
  end

  context 'when the carrier is no longer eligible' do
    before { allow_any_instance_of(Shipment).to(receive(:valid_broker_carriers_for_quotation).and_return(BrokerCarrier.none)) }

    it { expect(result['errors'].first['extensions']).to(eq('code' => 'UNBOOKABLE_RATE')) }
  end

  context 'when the shipment has no broker customer' do
    let(:authorizable) { create(:root_broker_user) }
    let(:shipment) do
      create(:shipment, booked_at: nil, broker_customer: nil, delivered_at: nil, dispatched_at: nil, picked_up_at: nil, quote_only: true)
    end

    it { expect(result['errors'].first['extensions']).to(eq('code' => 'NOT_FOUND')) }
  end

  context 'when the user is a carrier' do
    let(:authorizable) { create(:user, companyable: broker_carrier) }

    it { expect(result['errors'].first['extensions']).to(eq('code' => 'UNAUTHORIZED')) }
  end

  context 'when the user is another customer' do
    let(:authorizable) { create(:customer_user) }

    it { expect(result['errors'].first['extensions']).to(eq('code' => 'UNAUTHORIZED')) }
  end
end
