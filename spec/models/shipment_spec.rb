# frozen_string_literal: true

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

RSpec.describe(Shipment, type: :model) do
  it_behaves_like 'discussable'
  it_behaves_like 'documentable'

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
    it { is_expected.to(have_many(:items).through(:shipment_items)) }
    it { is_expected.to(have_many(:items).through(:shipment_items)) }
    it { is_expected.to(have_many(:payment_transactions)) }
    it { is_expected.to(have_many(:payments).through(:payment_transactions)) }
    it { is_expected.to(have_many(:pickups)) }
    it { is_expected.to(have_many(:problems)) }
    it { is_expected.to(have_many(:rates)) }
    it { is_expected.to(have_many(:shipment_accessorials)) }
    it { is_expected.to(have_many(:shipment_items)) }
    it { is_expected.to(have_many(:tracking_events)) }
  end

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
        receiver_names = [shipment.receiver_name, Faker::Company.name]

        expect { shipment.update(receiver_name: receiver_names[1]) }.to(change { shipment.audits.count }.by(1))
        audit = shipment.reload.audits.last

        expect(audit.action).to(eq('update'))
        expect(audit.audited_changes['receiver_name']).to(eq(receiver_names))
      end
    end
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

    it 'assigns a dispatcher' do
      expect { shipment.save }.to(change(shipment, :dispatcher).from(nil).to(user))
    end
  end

  describe '#picked_up?' do
    let(:shipment) { create(:shipment, picked_up_at: Time.current) }

    it { expect(shipment.picked_up?).to(eq(true)) }

    context 'when not picked_up_at.present?' do
      let(:shipment) { create(:shipment, picked_up_at: nil) }

      it { expect(shipment.picked_up?).to(eq(false)) }
    end
  end

  describe '#total_weight' do
    let(:shipment) do
      record = create(:shipment)
      record.items << create(:item, weight: 100)
      record.items << create(:item, weight: 100)
      record.save
      record
    end

    it 'returns sum of all items weight' do
      expect(shipment.total_weight).to(eq(200))
    end
  end

  describe '#total_pieces' do
    let(:shipment) do
      record = create(:shipment)
      record.items << create(:item, quantity: 5)
      record.items << create(:item, quantity: 5)
      record.save
      record
    end

    it 'returns sum of all items quantity' do
      expect(shipment.total_pieces).to(eq(10))
    end
  end

  describe '#total_density' do
    let(:shipment) do
      record = create(:shipment)
      record.items << create(:item, quantity: 5)
      record.save
      record
    end

    context 'when item density(rounded: false) is blank' do
      before do
        expect_any_instance_of(Item).to(receive(:density).with(rounded: false).and_return(nil))
      end

      it { expect(shipment.total_density(rounded: false)).to(be_nil) }
    end

    context 'when item density(rounded: false) is present' do
      before do
        expect_any_instance_of(Item).to(receive(:density).twice.with(rounded: false).and_return(100))
      end

      it { expect(shipment.total_density(rounded: false)).to(eq(100)) }
    end
  end

  describe '#total_cubic_ft' do
    let(:shipment) do
      record = create(:shipment)
      record.items << create(:item, quantity: 5)
      record.save
      record
    end

    context 'when item cubic_ft(rounded: false) is blank' do
      before do
        expect_any_instance_of(Item).to(receive(:cubic_ft).with(rounded: false).and_return(nil))
      end

      it { expect(shipment.total_cubic_ft(rounded: false)).to(be_nil) }
    end

    context 'when item cubic_ft(rounded: false) is present' do
      before do
        expect_any_instance_of(Item).to(receive(:cubic_ft).twice.with(rounded: false).and_return(100))
      end

      it { expect(shipment.total_cubic_ft(rounded: false)).to(eq(100)) }
    end
  end
end
