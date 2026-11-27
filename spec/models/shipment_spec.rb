require 'rails_helper'

RSpec.describe(Shipment) do
  it_behaves_like 'discussable'
  it_behaves_like 'documentable'

  describe '.address_name_sql' do
    subject { described_class.address_name_sql(:shipper) }

    it { is_expected.to(eq('(SELECT addresses.name FROM addresses WHERE addresses.id = shipments.shipper_address_id)')) }
  end

  describe '.ransack_aliases' do
    it { expect(described_class.ransack_aliases(build(:customer_user))).to(eq(described_class::CUSTOMER_REFERENCE_ALIASES)) }
    it { expect(described_class.ransack_aliases(build(:broker_user))).to(eq({})) }
    it { expect(described_class.ransack_aliases).to(eq({})) }
  end

  describe '.ransackable_attributes' do
    let(:note_columns) { ['broker_and_broker_customer_notes', 'broker_notes'] }

    it { expect(described_class.ransackable_attributes(build(:customer_user))).not_to(include(*described_class::CUSTOMER_HIDDEN_COLUMNS)) }
    it { expect(described_class.ransackable_attributes(build(:customer_user))).to(include('customer_pro')) }
    it { expect(described_class.ransackable_attributes).to(include('pro', 'tracking_carrier_pro')) }

    it { expect(described_class.ransackable_attributes).to(include('broker_carrier_id', 'broker_customer_id', 'status')) }
    it { expect(described_class.ransackable_attributes).not_to(include(*note_columns)) }
    it { expect(described_class.ransackable_attributes(build(:broker_user))).to(include(*note_columns)) }
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
        receiver_contact_names = [shipment.receiver_contact_name, Faker::Name.name]

        expect { shipment.update(receiver_contact_name: receiver_contact_names[1]) }.to(change { shipment.audits.count }.by(1))
        audit = shipment.reload.audits.last

        expect(audit.action).to(eq('update'))
        expect(audit.audited_changes['receiver_contact_name']).to(eq(receiver_contact_names))
      end
    end
  end

  describe 'load ID assignment' do
    before { create(:shipment, load_id: 4000) }

    it { expect(create(:shipment, load_id: nil).load_id).to(eq(4001)) }
    it { expect(create(:shipment, load_id: 5000).load_id).to(eq(5000)) }
  end

  describe 'name prettifying' do
    subject { shipment.shipper_address.name }

    let(:broker_customer) { create(:broker_customer) }
    let(:name) { 'ACME FOODS' }
    let(:shipment) { create(:shipment, broker_customer:, shipper_address: build(:address, name:, street:, street2:)) }
    let(:street) { '1 Main St' }
    let(:street2) { nil }

    it { is_expected.to(eq('Acme Foods')) }

    context 'when the name is the customer name' do
      let(:name) { broker_customer.customer.name.upcase }

      before { broker_customer.customer.update!(name:) }

      it { is_expected.to(eq(name)) }
    end

    context 'when the street is in care of someone' do
      let(:name) { 'Acme' }
      let(:street) { 'C/O Bob' }
      let(:street2) { '1 Main St' }

      it { is_expected.to(eq('Acme C/O Bob')) }
      it { expect(shipment.shipper_address).to(have_attributes(street: '1 Main St', street2: nil)) }
    end
  end

  describe 'name search' do
    let!(:shipment) { create(:shipment, shipper_address: create(:address, name: 'Acme')) }

    before { create(:shipment, shipper_address: create(:address, name: 'Zeta')) }

    it { expect(described_class.ransack(shipper_name_eq: 'Acme').result).to(contain_exactly(shipment)) }
    it { expect(described_class.ransack(receiver_name_eq: shipment.receiver_address.name).result).to(contain_exactly(shipment)) }
    it { expect(described_class.ransack(sorts: 'shipper_name asc').result.first).to(eq(shipment)) }
  end

  describe 'normalizations' do
    it { expect(described_class.new(bol: ' 1001  2 ').bol).to(eq('1001 2')) }
    it { expect(described_class.new(pro: ' 42  43 ').pro).to(eq('42 43')) }
  end

  describe 'notifications' do
    let(:actor) { create(:broker_user) }
    let(:shipment) { create(:shipment, delivered_at: nil, updated_by: nil) }

    before { allow(ShipmentNotifier).to(receive(:with).and_call_original) }

    context 'when a shipment is created' do
      before do
        allow(Rails.env).to(receive(:test?).and_return(false))
        create(:shipment, updated_by: actor)
      end

      it { expect(ShipmentNotifier).to(have_received(:with).with(hash_including(actor:, attribute_changed: :new_shipment))) }
    end

    context 'when a notifiable attribute changes' do
      before do
        shipment.assign_attributes(delivered_at: Time.current)
        shipment.updated_by = actor
        shipment.save!
      end

      it { expect(ShipmentNotifier).to(have_received(:with).with(actor:, attribute_changed: 'delivered_at', shipment:)) }
    end
  end

  describe 'relationships' do
    it { is_expected.to(belong_to(:applied_rate).required(false)) }
    it { is_expected.to(belong_to(:broker_carrier).required(false)) }
    it { is_expected.to(belong_to(:dispatcher)) }
    it { is_expected.to(belong_to(:pickup_request).inverse_of(:shipments).optional) }
    it { is_expected.to(belong_to(:receiver_address)) }
    it { is_expected.to(belong_to(:shipper_address)) }
    it { is_expected.to(belong_to(:tracking_carrier).required(false)) }

    it { is_expected.to(have_many(:accessorials).through(:shipment_accessorials)) }
    it { is_expected.to(have_many(:claims).dependent(:restrict_with_error)) }
    it { is_expected.to(have_many(:commissions)) }
    it { is_expected.to(have_many(:items)) }
    it { is_expected.to(have_many(:payment_transactions).dependent(:restrict_with_error)) }
    it { is_expected.to(have_many(:payments).through(:payment_transactions)) }
    it { is_expected.to(have_many(:pickups).dependent(:destroy)) }
    it { is_expected.to(have_many(:problems).dependent(:destroy)) }
    it { is_expected.to(have_many(:rates)) }
    it { is_expected.to(have_many(:receivables).dependent(:restrict_with_error)) }
    it { is_expected.to(have_many(:shipment_accessorials)) }
    it { is_expected.to(have_many(:suppressions).dependent(:destroy)) }
    it { is_expected.to(have_many(:tracking_events)) }
  end

  describe '#destroy' do
    subject { shipment.destroy }

    let(:shipment) { create(:shipment) }

    it { is_expected.to(be_destroyed) }

    context 'with a receivable' do
      before { build(:receivable, shipment:).save!(validate: false) }

      it { is_expected.to(be(false)) }
      it { expect { shipment.destroy }.not_to(change(described_class, :count)) }
    end
  end

  describe 'helpers' do
    let(:accessorial) { build(:accessorial, code: 'DLIF', name: 'Liftgate', transponder_code: 'liftgate_delivery') }
    let(:loose_item) { instance_double(Item) }
    let(:pallet_item) { instance_double(Item) }
    let(:shipment) { build(:shipment, broker_carrier: nil, load_id: 42) }

    describe '.ransackable_associations' do
      it do
        expect(described_class.ransackable_associations).to(eq(['broker_carrier', 'broker_customer', 'receiver_address',
                                                                'shipper_address']))
      end

      it { expect(described_class.ransackable_associations(build(:carrier_user))).not_to(include('broker_customer')) }
      it { expect(described_class.ransackable_associations(build(:customer_user))).not_to(include('broker_carrier')) }
    end

    describe '#accessorial_codes' do
      it { expect(shipment.accessorial_codes).to(eq([])) }

      context 'when the shipment has accessorials' do
        before do
          shipment.shipment_accessorials.build(accessorial:)
          shipment.shipment_accessorials.build(accessorial: build(:accessorial, code: nil, transponder_code: 'residential_delivery'))
        end

        it { expect(shipment.accessorial_codes).to(eq(['DLIF', 'residential_delivery'])) }
      end
    end

    describe '#accessorial_codes=' do
      let(:shipment) { create(:shipment, broker_carrier: nil) }
      let!(:liftgate) { create(:accessorial, code: 'DLIF') }

      before do
        create(:accessorial, broker_customer: create(:broker_customer), code: 'DRES')
        shipment.accessorial_codes = 'DLIF, DRES'
      end

      it { expect(shipment.accessorials).to(eq([liftgate])) }
    end

    describe '#assumed_accessorials' do
      let(:service) { instance_double(BuildAssumedAccesorialsService, call: [accessorial]) }

      before { allow(BuildAssumedAccesorialsService).to(receive(:new).with(shipment:).and_return(service)) }

      it { expect(shipment.assumed_accessorials).to(eq([accessorial])) }
    end

    describe '#combined_accessorials' do
      let(:custom) { build(:accessorial, code: 'WKND') }
      let(:liftgate) { build(:accessorial, transponder_code: 'liftgate_delivery') }
      let(:residential) { build(:accessorial, transponder_code: 'residential_delivery') }

      before do
        shipment.shipment_accessorials.build(accessorial:)
        shipment.shipment_accessorials.build(accessorial: custom)
        allow(shipment).to(receive(:assumed_accessorials).and_return([liftgate, residential]))
      end

      it { expect(shipment.combined_accessorials).to(eq([accessorial, custom, residential])) }
      it { expect(shipment.combined_transponder_accessorial_codes).to(eq(['liftgate_delivery', 'residential_delivery'])) }
    end

    describe '#selected_accessorials' do
      before do
        shipment.shipment_accessorials.build(accessorial:)
        shipment.shipment_accessorials.build(accessorial: build(:accessorial)).mark_for_destruction
      end

      it { expect(shipment.selected_accessorials).to(eq([accessorial])) }
    end

    describe '#broker_carrier_bol_requires_tracking_number?' do
      it { expect(shipment.broker_carrier_bol_requires_tracking_number?).to(be(false)) }

      context 'when the broker carrier requires it' do
        before { shipment.broker_carrier = build(:broker_carrier, carrier: build(:carrier, :saia)) }

        it { expect(shipment.broker_carrier_bol_requires_tracking_number?).to(be(true)) }
      end
    end

    describe '#calculated_freight_classes' do
      before do
        allow(pallet_item).to(receive(:api_freight_class).with(use_declared_freight_class: false).and_return(85))
        allow(shipment).to(receive(:items).and_return([pallet_item]))
      end

      it { expect(shipment.calculated_freight_classes).to(eq([85])) }
    end

    describe '#declared_freight_classes' do
      before do
        allow(pallet_item).to(receive(:api_freight_class).with(use_declared_freight_class: true).and_return(70))
        allow(shipment).to(receive(:items).and_return([pallet_item]))
      end

      it { expect(shipment.declared_freight_classes).to(eq([70])) }
      it { expect(shipment.freight_classes(use_declared_freight_class: true)).to(eq([70])) }
    end

    describe '#delivered?' do
      it { expect(shipment.delivered?).to(be(true)) }

      context 'when it is not delivered' do
        before { shipment.delivered_at = nil }

        it { expect(shipment.delivered?).to(be(false)) }
      end
    end

    describe '#delivery_from' do
      let(:delivery_date_service) { instance_double(Shipment::DeliveryDateService, delivery_from: Date.new(2026, 11, 2)) }

      before { allow(Shipment::DeliveryDateService).to(receive(:new).with(shipment:).and_return(delivery_date_service)) }

      it { expect(shipment.delivery_from).to(eq(Date.new(2026, 11, 2))) }
    end

    describe '#dispatcher_full_name' do
      it { expect(shipment.dispatcher_full_name).to(eq(shipment.dispatcher.full_name)) }
    end

    describe '#eligible_broker_carriers' do
      let!(:blanket) { create(:broker_carrier) }

      before { allow(shipment.broker_customer).to(receive(:eligible_broker_carriers).with(:broker).and_return([blanket])) }

      it { expect(shipment.eligible_broker_carriers(:broker)).to(eq([blanket])) }

      context 'when there is no broker customer' do
        before { shipment.broker_customer = nil }

        it { expect(shipment.eligible_broker_carriers).to(contain_exactly(blanket)) }
      end
    end

    describe '#incomplete?' do
      it { expect(shipment.incomplete?).to(be(false)) }

      context 'when the receiver name is blank' do
        before { shipment.receiver_address.name = nil }

        it { expect(shipment.incomplete?).to(be(true)) }
      end
    end

    describe '#loose?' do
      before { allow(shipment).to(receive_messages(items: [loose_item, pallet_item], palletized_items: [pallet_item])) }

      it { expect(shipment.loose?).to(be(true)) }
      it { expect(shipment.loose_items).to(eq([loose_item])) }
      it { expect(shipment.palletized?).to(be(false)) }
    end

    describe '#palletized?' do
      before { allow(shipment).to(receive_messages(items: [pallet_item], palletized_items: [pallet_item])) }

      it { expect(shipment.palletized?).to(be(true)) }
      it { expect(shipment.loose?).to(be(false)) }
      it { expect(shipment.loose_items).to(eq([])) }
    end

    describe '#margin' do
      before { shipment.assign_attributes(total_charges: Money.new(20_000, 'USD'), total_cost: Money.new(15_000, 'USD')) }

      it { expect(shipment.margin).to(eq('25.0%')) }
      it { expect(shipment.profit).to(eq(Money.new(5_000, 'USD'))) }

      context 'without charges' do
        before { shipment.total_charges = Money.new(0, 'USD') }

        it { expect(shipment.margin).to(be_nil) }
      end
    end

    describe '#missing_delivery_eta_on?' do
      it { expect(shipment.missing_delivery_eta_on?).to(be(false)) }

      context 'when it is blank' do
        before { shipment.delivery_eta_on = nil }

        it { expect(shipment.missing_delivery_eta_on?).to(be(true)) }
      end
    end

    describe '#profit' do
      before { shipment.assign_attributes(total_charges: Money.new(100, 'USD'), total_cost: Money.new(300, 'USD')) }

      it { expect(shipment.profit).to(eq(Money.new(-200, 'USD'))) }
    end

    describe '#recalculate_accessorials' do
      let(:broker_customer) { create(:broker_customer) }
      let(:blanket) { create(:accessorial, code: 'DLIF', transponder_code: 'liftgate_delivery') }
      let!(:customer) { create(:accessorial, broker_customer:, code: 'CLIF', transponder_code: 'liftgate_delivery') }
      let(:custom) { create(:accessorial, code: 'WKND') }

      before do
        shipment.shipment_accessorials.build(accessorial: blanket)
        shipment.shipment_accessorials.build(accessorial: custom)
        shipment.broker_customer = broker_customer
        shipment.__send__(:recalculate_accessorials)
      end

      it { expect(shipment.selected_accessorials).to(eq([customer, custom])) }
    end

    describe '#remove_applied_rate' do
      before do
        shipment.applied_rate = build(:rate)
        shipment.__send__(:remove_applied_rate)
      end

      it { expect(shipment.applied_rate).to(be_nil) }
    end

    describe '#remove_tracking_events' do
      let(:tracking_events) { double(destroy_all: []) }

      before do
        allow(shipment).to(receive(:tracking_events).and_return(tracking_events))
        shipment.__send__(:remove_tracking_events)
      end

      it { expect(tracking_events).to(have_received(:destroy_all)) }
    end

    describe '#suggested_accessorials' do
      let(:residential) { build(:accessorial, transponder_code: 'residential_delivery') }

      before { allow(shipment).to(receive(:assumed_accessorials).and_return([accessorial, residential])) }

      it { expect(shipment.suggested_accessorials).to(eq([accessorial, residential])) }

      context 'when the shipment already has an accessorial with the same Transponder code' do
        before do
          shipment.shipment_accessorials.build(accessorial: build(:accessorial, code: 'LIFT', transponder_code: 'liftgate_delivery'))
        end

        it { expect(shipment.suggested_accessorials).to(eq([residential])) }
      end
    end

    describe '#to_param' do
      it { expect(shipment.to_param).to(eq('42')) }
    end

    describe '#unbook' do
      before { shipment.__send__(:unbook) }

      it { expect(shipment.booked_at).to(be_nil) }
    end

    describe '#uncancel' do
      before { shipment.__send__(:uncancel) }

      it { expect(shipment.canceled_at).to(be_nil) }
    end
  end

  describe '#validate_pro_and_tracking_carrier_pro' do
    let(:broker_carrier) { create(:broker_carrier, carrier: create(:carrier, :saia)) }
    let(:carrier_name) { broker_carrier.carrier.name }
    let(:pro) { '12345678901' }
    let(:shipment) do
      build(:shipment, broker_carrier:, pro:, tracking_carrier:, tracking_carrier_pickup_confirmation: nil, tracking_carrier_pro:)
    end
    let(:tracking_carrier) { nil }
    let(:tracking_carrier_pro) { nil }

    before { shipment.__send__(:validate_pro_and_tracking_carrier_pro) }

    it { expect(shipment.errors).to(be_empty) }

    context 'when the pro does not match the carrier pattern' do
      let(:pro) { '1234' }

      it { expect(shipment.errors[:base]).to(eq(["Pro 1234 is invalid for #{broker_carrier.carrier.name}"])) }
    end

    context 'when the carrier is custom' do
      let(:broker_carrier) { create(:broker_carrier) }
      let(:pro) { '1234' }

      it { expect(shipment.errors).to(be_empty) }
    end

    context 'when the tracking carrier pro matches the pro' do
      let(:tracking_carrier) { create(:carrier) }
      let(:tracking_carrier_pro) { pro }

      it { expect(shipment.errors[:tracking_carrier_pro]).to(eq(["cannot match pro #{pro} from #{broker_carrier.carrier.name}"])) }
    end

    context 'when the tracking carrier pickup confirmation matches the pickup confirmation' do
      let(:shipment) do
        build(:shipment, broker_carrier:, pickup_confirmation: 'PU1', pro:, tracking_carrier:, tracking_carrier_pickup_confirmation: 'PU1')
      end
      let(:tracking_carrier) { create(:carrier) }

      it { expect(shipment.errors[:tracking_carrier_pickup_confirmation]).to(eq(["cannot match pickup ref PU1 from #{carrier_name}"])) }
    end
  end

  describe '#assign_dispatcher' do
    let(:user) do
      record = build(:broker_user)
      record.save!
      record.add_role(:dispatch)

      record
    end
    let(:shipment) do
      record = build(:shipment)
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
      fingerprint = fresh_shipment.__send__(:set_fingerprint)
      expect(fresh_shipment.flattened_items).to(be_present)

      fresh_shipment.flattened_items.each { |item| item.shipment_id = shipment.id + 1 }

      expect(fresh_shipment.__send__(:set_fingerprint)).to(eq(fingerprint))
    end

    it 'matches after the first save' do
      new_shipment = create(:shipment, value_cents: 1_000)
      fingerprint = new_shipment.fingerprint
      new_shipment.update!(bol_notes: 'Call ahead')

      expect(new_shipment.reload.fingerprint).to(eq(fingerprint))
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
        promised_delivery_by: nil
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

  describe '#customer_pro' do
    subject { shipment.customer_pro }

    let(:shipment) { build(:shipment, pro: 'BROKER', tracking_carrier:, tracking_carrier_pro: 'CARRIER') }
    let(:tracking_carrier) { create(:carrier) }

    it { is_expected.to(eq('CARRIER')) }

    context 'without a tracking carrier' do
      let(:tracking_carrier) { nil }

      it { is_expected.to(eq('BROKER')) }
    end
  end

  describe '#late_since' do
    subject { shipment.late_since }

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
        promised_delivery_by: nil
      )
    end

    context 'when delivered_at is present' do
      before do
        shipment.delivered_at = 1.hour.ago
        shipment.delivery_eta_on = 3.days.ago.to_date
        shipment.picked_up_at = 5.days.ago
      end

      it { is_expected.to(be_nil) }
    end

    context 'when picked_up_at is present' do
      before { shipment.picked_up_at = 5.days.ago }

      context 'when delivery_appointment_at is in the past' do
        before { shipment.delivery_appointment_at = 1.hour.ago.change(usec: 0) }

        it { is_expected.to(eq(shipment.delivery_appointment_at)) }
      end

      context 'when delivery_appointment_at is in the future' do
        before do
          shipment.delivery_appointment_at = 1.day.from_now
          shipment.delivery_eta_on = 3.days.ago.to_date
        end

        it { is_expected.to(be_nil) }
      end

      context 'when delivery_appointment_on is yesterday' do
        before { shipment.delivery_appointment_on = Date.yesterday }

        it { is_expected.to(eq(Date.current.beginning_of_day)) }
      end

      context 'when delivery_appointment_on is today' do
        before { shipment.delivery_appointment_on = Date.current }

        it { is_expected.to(be_nil) }
      end

      context 'when delivery_eta_on is two days ago' do
        before { shipment.delivery_eta_on = 2.days.ago.to_date }

        it { is_expected.to(eq(Date.yesterday.beginning_of_day)) }
      end

      context 'when promised_delivery_by is earlier than the delivery schedule' do
        before do
          shipment.delivery_eta_on = Date.yesterday
          shipment.promised_delivery_by = 3.days.ago
        end

        it { is_expected.to(eq(2.days.ago.to_date.beginning_of_day)) }
      end

      context 'when no delivery dates are set' do
        it { is_expected.to(be_nil) }
      end
    end

    context 'when not yet picked up' do
      context 'when pickup_by is in the past' do
        let(:pickup_by) { 1.hour.ago }

        before { allow(shipment).to(receive(:pickup_by).and_return(pickup_by)) }

        it { is_expected.to(eq(pickup_by)) }
      end

      context 'when pickup_by is in the future' do
        before { allow(shipment).to(receive(:pickup_by).and_return(1.hour.from_now)) }

        it { is_expected.to(be_nil) }
      end

      context 'when pickup_by is nil' do
        it { is_expected.to(be_nil) }
      end
    end
  end

  describe '#missed_pickup?' do
    subject { shipment.missed_pickup? }

    let(:shipment) { build(:shipment, picked_up_at: nil, pickup_driver_assigned_at: 2.days.ago, pickup_on: 2.days.ago) }

    before { create(:setting, key: 'time_zone_name', value: 'America/Los_Angeles') }

    it { is_expected.to(be(true)) }

    context 'when the freight was picked up' do
      before { shipment.picked_up_at = 1.day.ago }

      it { is_expected.to(be(false)) }
    end

    context 'when the pickup is in the future' do
      before { shipment.pickup_on = 2.days.from_now }

      it { is_expected.to(be(false)) }
    end

    context 'without a driver assigned' do
      before { shipment.pickup_driver_assigned_at = nil }

      it { is_expected.to(be(false)) }
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
    subject { shipment.tap { |record| record.__send__(:set_status) }.status }

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
        total_charges_cents: nil
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

  describe '#total_accessorial_charge' do
    let(:shipment) { build(:shipment) }

    it { expect(shipment.total_accessorial_charge).to(eq(0)) }

    context 'with accessorials' do
      before do
        shipment.shipment_accessorials.build(accessorial: build(:accessorial), charge: 10, cost: 4)
        shipment.shipment_accessorials.build(accessorial: build(:accessorial), charge: 5, cost: 2)
      end

      it { expect(shipment.total_accessorial_charge).to(eq(Money.from_amount(15))) }
      it { expect(shipment.total_accessorial_cost).to(eq(Money.from_amount(6))) }
    end
  end

  describe '#total_accessorial_cost' do
    it { expect(build(:shipment).total_accessorial_cost).to(eq(0)) }
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

      it { is_expected.to(eq(500)) }
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

  describe '.accessible_by' do
    subject { described_class.accessible_by(user) }

    let!(:sales_rep_shipment) { create(:shipment) }
    let!(:shipment) { create(:shipment) }
    let(:user) { create(:broker_user).tap { |user| user.add_role(:accounts_payable) } }

    it { is_expected.to(include(sales_rep_shipment, shipment)) }

    context 'with a customer user' do
      let(:user) { create(:customer_user, companyable: shipment.broker_customer) }

      it { is_expected.to(contain_exactly(shipment)) }
    end

    context 'with a sales rep' do
      let(:user) do
        create(:broker_user).tap do |user|
          user.broker_customer_sales_reps.create!(broker_customer: sales_rep_shipment.broker_customer, commission_percent: 10)
        end
      end

      it { is_expected.to(contain_exactly(sales_rep_shipment)) }
    end

    context 'without a user' do
      let(:user) { nil }

      it { is_expected.to(be_empty) }
    end
  end

  describe '.delivered_to' do
    let!(:shipment) { create(:shipment) }

    it { expect(described_class.delivered_to(shipment.receiver_address.zip_code)).to(include(shipment)) }
    it { expect(described_class.delivered_to('00000')).not_to(include(shipment)) }
  end

  describe '.last_load_id' do
    before { create(:setting, key: 'first_load_id', value: '1000') }

    it { expect(described_class.last_load_id).to(eq(1000)) }

    context 'when shipments exist' do
      before { create(:shipment, load_id: 1234) }

      it { expect(described_class.last_load_id).to(eq(1234)) }
    end

    context 'when first_load_id is missing' do
      before { Setting.find_by(key: 'first_load_id').destroy! }

      it { expect(described_class.last_load_id).to(eq(0)) }
    end
  end

  describe '.lock_load_ids' do
    let(:advisory_locks) { "SELECT count(*) FROM pg_locks WHERE locktype = 'advisory' AND pid = pg_backend_pid()" }

    it do
      described_class.transaction do
        described_class.lock_load_ids

        expect(described_class.connection.select_value(advisory_locks)).to(eq(1))
      end
    end
  end

  describe '.missed_pickup' do
    let!(:shipment) { create(:shipment, picked_up_at: nil, pickup_driver_assigned_at: 2.days.ago, pickup_on: 2.days.ago) }

    before { create(:setting, key: 'time_zone_name', value: 'America/Los_Angeles') }

    it { expect(described_class.missed_pickup).to(include(shipment)) }

    context 'when the pickup is in the future' do
      before { shipment.update!(pickup_on: 2.days.from_now) }

      it { expect(described_class.missed_pickup).not_to(include(shipment)) }
    end
  end

  describe '.missing_delivery_appointment' do
    let(:shipment) do
      create(
        :shipment,
        :usd,
        canceled_at: nil,
        delivered_at: nil,
        delivery_appointment_at: nil,
        delivery_appointment_on: nil,
        pending_appointment_since: nil,
        picked_up_at: 1.day.ago
      )
    end

    before { shipment.shipment_accessorials.create!(accessorial: create(:accessorial, transponder_code: 'appointment_delivery')) }

    it { expect(described_class.missing_delivery_appointment).to(include(shipment)) }

    context 'when the delivery appointment is set' do
      before { shipment.update!(delivery_appointment_on: Date.current) }

      it { expect(described_class.missing_delivery_appointment).not_to(include(shipment)) }
    end
  end

  describe '.shipped_from' do
    let!(:shipment) { create(:shipment) }

    it { expect(described_class.shipped_from(shipment.shipper_address.zip_code)).to(include(shipment)) }
    it { expect(described_class.shipped_from('00000')).not_to(include(shipment)) }
  end

  describe '#eligible_discussable_contacts' do
    let(:record) { create(:shipment, broker_customer: nil, updated_by: nil) }

    it { expect(record.eligible_discussable_contacts).to(include(record.dispatcher.contact)) }
  end

  describe '#requires_charges_confirmed_on_receivables?' do
    let(:record) { build(:shipment) }

    before { record.broker_customer.requires_charges_confirmed_on_receivables = false }

    it { expect(record).not_to(be_requires_charges_confirmed_on_receivables) }

    context 'when the requires_charges_confirmed_on_receivables setting is true' do
      before { create(:setting, key: 'requires_charges_confirmed_on_receivables', value: true) }

      it { expect(record).to(be_requires_charges_confirmed_on_receivables) }
    end
  end

  describe '#users_to_notify' do
    let(:record) { create(:shipment, updated_by: nil) }
    let!(:dispatcher) { create(:broker_user).tap { |user| user.add_role(:dispatch) } }

    before { create(:customer_user).tap { |user| user.add_role(:dispatch) } }

    it { expect(record.users_to_notify).to(include(dispatcher)) }
    it { expect(record.users_to_notify).to(all(be_broker)) }
  end

  describe '#valid_broker_carriers_for_quotation' do
    let(:record) { build(:shipment, broker_customer: nil) }
    let!(:broker_carrier) { create(:broker_carrier, broker_customer: nil) }

    before { allow(BrokerCarrier).to(receive(:blanket).and_return(BrokerCarrier.where(id: broker_carrier.id))) }

    it { expect { record.valid_broker_carriers_for_quotation }.not_to(raise_error) }
  end
end
