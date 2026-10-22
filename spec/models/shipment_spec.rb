# == Schema Information
#
# Table name: shipments
#
# @!attribute id
#   @return [Integer]
# @!attribute bol
#   @return [String]
# @!attribute bol_notes
#   @return [String]
# @!attribute booked_at
#   @return [Time]
# @!attribute broker_and_broker_customer_notes
#   @return [String]
# @!attribute broker_bol_shipment_fingerprint
#   @return [String]
# @!attribute broker_dispatch_sheet_shipment_fingerprint
#   @return [String]
# @!attribute broker_notes
#   @return [String]
# @!attribute broker_quote_shipment_fingerprint
#   @return [String]
# @!attribute canceled_at
#   @return [Time]
# @!attribute carrier_charge_cents
#   @return [Integer]
# @!attribute carrier_charge_currency
#   @return [String]
# @!attribute carrier_cost_cents
#   @return [Integer]
# @!attribute carrier_cost_currency
#   @return [String]
# @!attribute charges_confirmed
#   @return [Boolean]
# @!attribute customer_notes
#   @return [String]
# @!attribute customer_reference
#   @return [String]
# @!attribute delivered_at
#   @return [Time]
# @!attribute delivery_appointment_at
#   @return [Time]
# @!attribute delivery_appointment_on
#   @return [Date]
# @!attribute delivery_eta_on
#   @return [Date]
# @!attribute delivery_hours_end_at
#   @return [String]
# @!attribute delivery_hours_start_at
#   @return [String]
# @!attribute departed_origin_terminal_at
#   @return [Time]
# @!attribute dispatched_at
#   @return [Time]
# @!attribute lift_gate_delivery
#   @return [Boolean]
# @!attribute lift_gate_pickup
#   @return [Boolean]
# @!attribute load
#   @return [Integer]
# @!attribute lost_on
#   @return [Date]
# @!attribute notify
#   @return [Boolean]
# @!attribute out_for_delivery_at
#   @return [Time]
# @!attribute pending_appointment_since
#   @return [Date]
# @!attribute picked_up
#   @return [Boolean]
# @!attribute picked_up_at
#   @return [Time]
# @!attribute pickup_confirmation
#   @return [String]
# @!attribute pickup_driver_assigned_at
#   @return [Time]
# @!attribute pickup_eta_at
#   @return [String]
# @!attribute pickup_hours_end_at
#   @return [String]
# @!attribute pickup_hours_start_at
#   @return [String]
# @!attribute pickup_on
#   @return [Date]
# @!attribute priority
#   @return [Integer]
# @!attribute pro
#   @return [String]
# @!attribute promised_delivery_by
#   @return [Time]
# @!attribute public_notes
#   @return [String]
# @!attribute quote_only
#   @return [Boolean]
# @!attribute quoted_delivery_by
#   @return [Time]
# @!attribute receiver_available_at
#   @return [Time]
# @!attribute receiver_contact_email
#   @return [String]
# @!attribute receiver_contact_name
#   @return [String]
# @!attribute receiver_contact_phone
#   @return [String]
# @!attribute receiver_name
#   @return [String]
# @!attribute receiver_unavailable_at
#   @return [Time]
# @!attribute shipper_available_at
#   @return [Time]
# @!attribute shipper_bol
#   @return [String]
# @!attribute shipper_contact_email
#   @return [String]
# @!attribute shipper_contact_name
#   @return [String]
# @!attribute shipper_contact_phone
#   @return [String]
# @!attribute shipper_name
#   @return [String]
# @!attribute shipper_reference
#   @return [String]
# @!attribute shipper_unavailable_at
#   @return [Time]
# @!attribute total_charges_cents
#   @return [Integer]
# @!attribute total_charges_currency
#   @return [String]
# @!attribute total_cost_cents
#   @return [Integer]
# @!attribute total_cost_currency
#   @return [String]
# @!attribute tracking_carrier_pickup_confirmation
#   @return [String]
# @!attribute tracking_carrier_pro
#   @return [String]
# @!attribute truckload
#   @return [Boolean]
# @!attribute value_cents
#   @return [Integer]
# @!attribute value_currency
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute applied_rate_id
#   @return []
# @!attribute broker_carrier_id
#   @return [Integer]
# @!attribute broker_customer_id
#   @return []
# @!attribute broker_id
#   @return [Integer]
# @!attribute created_by_id
#   @return []
# @!attribute dispatcher_id
#   @return []
# @!attribute load_id
#   @return [Integer]
# @!attribute quote_id
#   @return [String]
# @!attribute receiver_address_id
#   @return []
# @!attribute shipper_address_id
#   @return []
# @!attribute tracking_carrier_id
#   @return []
# @!attribute updated_by_id
#   @return []
#
# Indexes
#
#  index_shipments_on_applied_rate_id        (applied_rate_id)
#  index_shipments_on_broker_customer_id     (broker_customer_id)
#  index_shipments_on_broker_id_and_load_id  (broker_id,load_id) UNIQUE
#  index_shipments_on_broker_notes           (broker_notes)
#  index_shipments_on_created_by_id          (created_by_id)
#  index_shipments_on_dispatcher_id          (dispatcher_id)
#  index_shipments_on_receiver_address_id    (receiver_address_id)
#  index_shipments_on_shipper_address_id     (shipper_address_id)
#  index_shipments_on_tracking_carrier_id    (tracking_carrier_id)
#  index_shipments_on_updated_by_id          (updated_by_id)
#
# Foreign Keys
#
#  fk_rails_...  (applied_rate_id => rates.id)
#  fk_rails_...  (broker_customer_id => broker_customers.id)
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (dispatcher_id => users.id)
#  fk_rails_...  (receiver_address_id => addresses.id)
#  fk_rails_...  (shipper_address_id => addresses.id)
#  fk_rails_...  (tracking_carrier_id => carriers.id)
#  fk_rails_...  (updated_by_id => users.id)
#
require 'rails_helper'

RSpec.describe(Shipment) do
  it_behaves_like 'discussable'
  it_behaves_like 'documentable'

  describe 'audits' do
    context 'when shipment is created' do
      let(:shipment) { build(:shipment) }

      it 'creates an audit record' do
        expect { shipment.save }.to(change { shipment.audits.count }.by(1))
        audit = shipment.reload.audits.last

        expect(audit.action).to(eq('create'))
      end
    end

    context 'when shipment is updated' do
      let(:shipment) { create(:shipment) }

      it 'creates an audit record' do
        receiver_names = [ shipment.receiver_name, Faker::Company.name ]

        expect { shipment.update(receiver_name: receiver_names[1]) }.to(change { shipment.audits.count }.by(1))
        audit = shipment.reload.audits.last

        expect(audit.action).to(eq('update'))
        expect(audit.audited_changes['receiver_name']).to(eq(receiver_names))
      end
    end
  end

  describe 'relationships' do
    it { is_expected.to(belong_to(:applied_rate).required(false)) }
    it { is_expected.to(belong_to(:broker_carrier).required(false)) }
    it { is_expected.to(belong_to(:broker)) }
    it { is_expected.to(belong_to(:dispatcher)) }
    it { is_expected.to(belong_to(:receiver_address)) }
    it { is_expected.to(belong_to(:shipper_address)) }
    it { is_expected.to(belong_to(:tracking_carrier).required(false)) }

    it { is_expected.to(have_many(:accessorials).through(:shipment_accessorials)) }
    it { is_expected.to(have_many(:commissions)) }
    it { is_expected.to(have_many(:items)) }
    it { is_expected.to(have_many(:payment_transactions)) }
    it { is_expected.to(have_many(:payments).through(:payment_transactions)) }
    it { is_expected.to(have_many(:pickups)) }
    it { is_expected.to(have_many(:problems)) }
    it { is_expected.to(have_many(:rates)) }
    it { is_expected.to(have_many(:shipment_accessorials)) }
    it { is_expected.to(have_many(:tracking_events)) }
  end

  describe '#assign_dispatcher' do
    let!(:broker) { create(:broker) }
    let(:user) do
      record = build(:user, companyable: broker)
      record.save!
      record.add_role(:dispatch)

      record
    end
    let(:shipment) do
      record = build(:shipment, broker:)
      record.dispatcher = nil
      record
    end

    it { expect { shipment.save }.to(change(shipment, :dispatcher).from(nil).to(user)) }
  end

  describe '#fingerprint' do
    let(:shipment) { create(:shipment) }

    before { create(:item, shipment:) }

    it 'ignores item shipment_id' do
      fresh_shipment = described_class.find(shipment.id)
      fingerprint = fresh_shipment.send(:set_fingerprint)
      expect(fresh_shipment.flattened_items).to(be_present)

      fresh_shipment.flattened_items.each { |item| item.shipment_id = shipment.id + 1 }

      expect(fresh_shipment.send(:set_fingerprint)).to(eq(fingerprint))
    end
  end

  describe '#late?' do
    subject { shipment.late? }

    let(:shipment) do
      build(
        :shipment,
        delivered_at: nil,
        delivery_appointment_at: nil,
        delivery_appointment_on: nil,
        delivery_eta_on: nil,
        picked_up_at: nil,
        pickup_confirmation: nil,
        pickup_hours_end_at: nil,
        pickup_on: nil,
        promised_delivery_by: nil,
      )
    end

    context 'when delivered_at is present' do
      before { shipment.delivered_at = 1.hour.ago }

      it { is_expected.to(be(false)) }
    end

    context 'when picked_up_at is present' do
      before { shipment.picked_up_at = 5.days.ago }

      context 'when delivery_appointment_at is in the past' do
        before { shipment.delivery_appointment_at = 1.hour.ago }

        it { is_expected.to(be(true)) }
      end

      context 'when delivery_appointment_at is in the future' do
        before { shipment.delivery_appointment_at = 1.day.from_now }

        it { is_expected.to(be_falsy) }
      end

      context 'when delivery_appointment_on is yesterday' do
        before { shipment.delivery_appointment_on = 1.day.ago.to_date }

        it { is_expected.to(be(true)) }
      end

      context 'when delivery_appointment_on is today' do
        before { shipment.delivery_appointment_on = Date.current }

        it { is_expected.to(be_falsy) }
      end

      context 'when delivery_eta_on is yesterday' do
        before { shipment.delivery_eta_on = 1.day.ago.to_date }

        it { is_expected.to(be(true)) }
      end

      context 'when delivery_eta_on is today' do
        before { shipment.delivery_eta_on = Date.current }

        it { is_expected.to(be_falsy) }
      end

      context 'when promised_delivery_by is in the past' do
        before { shipment.promised_delivery_by = 2.days.ago }

        it { is_expected.to(be_truthy) }
      end

      context 'when promised_delivery_by is in the future' do
        before { shipment.promised_delivery_by = 2.days.from_now }

        it { is_expected.to(be_falsy) }
      end

      context 'when no delivery dates are set' do
        it { is_expected.to(be_falsy) }
      end
    end

    context 'when not yet picked up' do
      context 'when pickup_by is in the past' do
        before { allow(shipment).to(receive(:pickup_by).and_return(1.hour.ago)) }

        it { is_expected.to(be_truthy) }
      end

      context 'when pickup_by is in the future' do
        before { allow(shipment).to(receive(:pickup_by).and_return(1.hour.from_now)) }

        it { is_expected.to(be_falsy) }
      end

      context 'when pickup_by is nil' do
        it { is_expected.to(be_falsy) }
      end
    end
  end

  describe '#picked_up?' do
    subject { shipment.picked_up? }

    let(:shipment) { create(:shipment, picked_up_at: Faker::Time.backward) }

    it { is_expected.to(be(true)) }

    context 'when picked_up_at is nil' do
      let(:shipment) { create(:shipment, picked_up_at: nil) }

      it { is_expected.to(be(false)) }
    end
  end

  describe '#status' do
    subject { shipment.tap { |record| record.send(:set_status) }.status }

    let(:shipment) do
      build(
        :shipment,
        booked_at: nil,
        canceled_at: nil,
        delivered_at: nil,
        delivery_appointment_at: nil,
        delivery_appointment_on: nil,
        delivery_eta_on: nil,
        dispatched_at: nil,
        out_for_delivery_at: nil,
        pending_appointment_since: nil,
        picked_up_at: nil,
        pickup_confirmation: nil,
        pickup_hours_end_at: nil,
        pickup_on: nil,
        promised_delivery_by: nil,
        total_charges_cents: nil,
      )
    end

    context 'when no status fields are set' do
      it { is_expected.to(eq('new_shipment')) }
    end

    context 'when booked_at' do
      before { shipment.booked_at = 1.day.ago }

      it { is_expected.to(eq('booked')) }
    end

    context 'when total_charges' do
      before { shipment.total_charges_cents = 500 }

      it { is_expected.to(eq('quoted')) }
    end

    context 'when booked_at and total_charges' do
      before do
        shipment.booked_at = 1.day.ago
        shipment.total_charges_cents = 500
      end

      it { is_expected.to(eq('booked_quoted')) }
    end

    context 'when dispatched_at' do
      before { shipment.dispatched_at = 1.day.ago }

      it { is_expected.to(eq('dispatched')) }
    end

    context 'when pickup_confirmation and pickup_by' do
      before do
        shipment.pickup_confirmation = 'CONF123'
        shipment.pickup_on = 2.days.from_now.to_date
        shipment.pickup_hours_end_at = '17:00'
      end

      it { is_expected.to(eq('pickup_scheduled')) }
    end

    context 'when picked_up_at' do
      before { shipment.picked_up_at = 1.day.ago }

      it { is_expected.to(eq('in_transit')) }
    end

    context 'when pending_appointment_since' do
      before do
        shipment.picked_up_at = 5.days.ago
        shipment.pending_appointment_since = 3.days.ago.to_date
      end

      it { is_expected.to(eq('pending_delivery_appointment')) }
    end

    context 'when delivery_appointment_at' do
      before do
        shipment.picked_up_at = 2.days.ago
        shipment.delivery_appointment_at = 1.day.from_now
      end

      it { is_expected.to(eq('delivery_scheduled')) }
    end

    context 'when delivery_appointment_on' do
      before do
        shipment.picked_up_at = 2.days.ago
        shipment.delivery_appointment_on = 1.day.from_now.to_date
      end

      it { is_expected.to(eq('delivery_scheduled')) }
    end

    context 'when out_for_delivery_at' do
      before do
        shipment.picked_up_at = 2.days.ago
        shipment.out_for_delivery_at = 1.hour.ago
      end

      it { is_expected.to(eq('out_for_delivery')) }
    end

    context 'when delivered_at' do
      before { shipment.delivered_at = 1.hour.ago }

      it { is_expected.to(eq('delivered')) }
    end

    context 'when canceled_at' do
      before { shipment.canceled_at = 1.hour.ago }

      it { is_expected.to(eq('canceled')) }
    end

    context 'when canceled_at, delivered_at' do
      before do
        shipment.canceled_at = 1.hour.ago
        shipment.delivered_at = 2.hours.ago
      end

      it { is_expected.to(eq('canceled')) }
    end

    context 'when late?' do
      before do
        shipment.delivery_eta_on = 2.days.ago.to_date
        shipment.picked_up_at = 5.days.ago
      end

      it { is_expected.to(eq('in_transit')) }
    end

    context 'when late?, not delivered_at' do
      before do
        shipment.delivered_at = 1.hour.ago
        shipment.delivery_eta_on = 2.days.ago.to_date
        shipment.picked_up_at = 5.days.ago
      end

      it { is_expected.to(eq('delivered')) }
    end
  end

  describe '#total_cubic_ft' do
    subject { shipment.total_cubic_ft(rounded: false) }

    let(:shipment) do
      record = create(:shipment)
      record.items << create(:item, quantity: 5)
      record.save
      record
    end

    context 'when item cubic_ft(rounded: false) is blank' do
      before { allow_any_instance_of(Item).to(receive(:cubic_ft).with(rounded: false).and_return(nil)) }

      it { is_expected.to(be_nil) }
    end

    context 'when item cubic_ft(rounded: false) is present' do
      before { allow_any_instance_of(Item).to(receive(:cubic_ft).with(rounded: false).and_return(100)) }

      it { is_expected.to(eq(100)) }
    end
  end

  describe '#total_density' do
    subject { shipment.total_density(rounded: false) }

    let(:shipment) do
      record = create(:shipment)
      record.items << create(:item, quantity: 5)
      record.save
      record
    end

    context 'when item density(rounded: false) is blank' do
      before { allow_any_instance_of(Item).to(receive(:density).with(rounded: false).and_return(nil)) }

      it { is_expected.to(be_nil) }
    end

    context 'when item density(rounded: false) is present' do
      before { allow_any_instance_of(Item).to(receive(:density).with(rounded: false).and_return(100)) }

      it { is_expected.to(eq(100)) }
    end
  end

  describe '#total_pieces' do
    subject { shipment.total_pieces }

    let(:shipment) do
      record = create(:shipment)
      record.items << create(:item, quantity: 5)
      record.items << create(:item, quantity: 5)
      record.save
      record
    end

    it { is_expected.to(eq(10)) }
  end

  describe '#total_weight' do
    subject { shipment.total_weight }

    let(:shipment) do
      record = create(:shipment)
      record.items << create(:item, weight: 100)
      record.items << create(:item, weight: 100)
      record.save
      record
    end

    it { is_expected.to(eq(200)) }
  end
end
