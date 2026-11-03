require 'rails_helper'

RSpec.describe(ShipmentPolicy) do
  let(:authorizable) { build(:broker_user) }
  let(:policy) { described_class.new(shipment, authorizable:) }
  let(:shipment) { build(:shipment) }

  describe '#apply_scope' do
    subject { policy.apply_scope(Shipment.all, type: :active_record_relation) }

    let(:authorizable) { create(:broker_user) }
    let(:broker_carrier) { create(:broker_carrier) }
    let!(:other_shipment) { create(:shipment, broker_carrier:) }
    let!(:sales_rep_shipment) { create(:shipment, broker_carrier:) }
    let!(:unassigned_shipment) { create(:shipment, broker_carrier:, broker_customer: nil) }

    before { BrokerCustomerSalesRep.create!(broker_customer: sales_rep_shipment.broker_customer, commission_percent: 5, user: authorizable) } # rubocop:disable Layout/LineLength

    it { is_expected.to(contain_exactly(sales_rep_shipment, unassigned_shipment)) }

    context 'when authorizable.is_a?(BrokerCarrier)' do
      let(:policy) { described_class.new(shipment, authorizable: broker_carrier) }

      it { is_expected.to(contain_exactly(other_shipment, sales_rep_shipment, unassigned_shipment)) }
    end

    context 'when not authorizable.is_a?(User)' do
      let(:policy) { described_class.new(shipment, authorizable: create(:customer)) }

      it { is_expected.to(be_empty) }
    end

    context 'when authorizable.carrier?' do
      let(:authorizable) { create(:user, companyable: carrier_shipment.broker_carrier) }
      let(:carrier_shipment) { create(:shipment, broker_carrier: create(:broker_carrier)) }

      it { is_expected.to(contain_exactly(carrier_shipment)) }
    end

    context 'when authorizable.customer?' do
      let(:authorizable) { create(:customer_user, companyable: other_shipment.broker_customer) }

      it { is_expected.to(contain_exactly(other_shipment)) }
    end

    context 'with an accounts or dispatch role' do
      before { authorizable.add_role(:accounts_receivable) }

      it { is_expected.to(contain_exactly(other_shipment, sales_rep_shipment, unassigned_shipment)) }
    end
  end

  describe '#create?' do
    subject { policy.apply(:create?) }

    it { is_expected.to(be(true)) }

    context 'when not authorizable.is_a?(User)' do
      let(:policy) { described_class.new(shipment, authorizable: build(:customer)) }

      it { is_expected.to(be(false)) }
    end

    context 'when authorizable.carrier?' do
      let(:authorizable) { build(:user, companyable: build(:broker_carrier)) }

      it { is_expected.to(be(false)) }
    end

    context 'when authorizable.customer?' do
      let(:authorizable) { build(:customer_user) }

      it { is_expected.to(be(true)) }
    end
  end

  describe '#fetch_rates?' do
    subject { policy.apply(:fetch_rates?) }

    before { allow_any_instance_of(Shipment).to(receive(:accessible_by?).with(authorizable).and_return(true)) }

    it { is_expected.to(be(true)) }

    context 'when authorizable.carrier?' do
      let(:authorizable) { build(:user, companyable: build(:broker_carrier)) }
      let(:shipment) { build(:shipment, broker_carrier: authorizable.companyable) }

      it { is_expected.to(be(false)) }
    end
  end

  describe '#index?' do
    subject { policy.apply(:index?) }

    it { is_expected.to(be(true)) }

    context 'when authorizable.is_a?(BrokerCarrier)' do
      let(:policy) { described_class.new(shipment, authorizable: build(:broker_carrier)) }

      it { is_expected.to(be(false)) }
    end

    context 'when authorizable.carrier?' do
      let(:authorizable) { build(:user, companyable: build(:broker_carrier)) }

      it { is_expected.to(be(false)) }
    end

    context 'when authorizable.customer?' do
      let(:authorizable) { build(:customer_user) }

      it { is_expected.to(be(true)) }
    end
  end

  describe '#manage?' do
    subject { policy.apply(:manage?) }

    context 'when accessible_by?' do
      before { allow(shipment).to(receive(:accessible_by?).with(authorizable).and_return(true)) }

      it { is_expected.to(be(true)) }
    end

    context 'when not accessible_by?' do
      before { allow(shipment).to(receive(:accessible_by?).with(authorizable).and_return(false)) }

      it { is_expected.to(be(false)) }
    end

    context 'when not authorizable.is_a?(User)' do
      let(:policy) { described_class.new(shipment, authorizable: build(:customer)) }

      it { is_expected.to(be(false)) }
    end

    context 'when authorizable.carrier? and the shipment is theirs' do
      let(:authorizable) { build(:user, companyable: build(:broker_carrier)) }
      let(:shipment) { build(:shipment, broker_carrier: authorizable.companyable) }

      it { is_expected.to(be(false)) }
    end
  end

  describe '#view?' do
    subject { policy.apply(:view?) }

    context 'when accessible_by?' do
      before { allow_any_instance_of(Shipment).to(receive(:accessible_by?).with(authorizable).and_return(true)) }

      it { is_expected.to(be(true)) }
    end

    context 'when authorizable.is_a?(BrokerCarrier) and the shipment is not theirs' do
      let(:policy) { described_class.new(shipment, authorizable: build(:broker_carrier)) }
      let(:shipment) { build(:shipment, broker_carrier: build(:broker_carrier)) }

      it { is_expected.to(be(false)) }
    end

    context 'when authorizable.is_a?(BrokerCarrier) and the shipment is theirs' do
      let(:policy) { described_class.new(shipment, authorizable: shipment.broker_carrier) }
      let(:shipment) { build(:shipment, broker_carrier: build(:broker_carrier)) }

      it { is_expected.to(be(true)) }
    end

    context 'when not accessible_by?' do
      before { allow_any_instance_of(Shipment).to(receive(:accessible_by?).with(authorizable).and_return(false)) }

      it { is_expected.to(be(false)) }
    end

    context 'when not authorizable.is_a?(User)' do
      let(:policy) { described_class.new(shipment, authorizable: build(:customer)) }

      it { is_expected.to(be(false)) }
    end

    context 'when the record is nil' do
      let(:shipment) { nil }

      it { is_expected.to(be(false)) }
    end

    context 'when authorizable.carrier? and the shipment is not theirs' do
      let(:authorizable) { build(:user, companyable: build(:broker_carrier)) }
      let(:shipment) { build(:shipment, broker_carrier: build(:broker_carrier)) }

      it { is_expected.to(be(false)) }
    end

    context 'when authorizable.carrier? and the shipment is theirs' do
      let(:authorizable) { build(:user, companyable: build(:broker_carrier)) }
      let(:shipment) { build(:shipment, broker_carrier: authorizable.companyable) }

      it { is_expected.to(be(true)) }
    end
  end

  describe '#view_carrier_references?' do
    subject { policy.apply(:view_carrier_references?) }

    it { is_expected.to(be(true)) }

    context 'when authorizable.is_a?(BrokerCarrier)' do
      let(:policy) { described_class.new(shipment, authorizable: build(:broker_carrier)) }

      it { is_expected.to(be(true)) }
    end

    context 'when authorizable.customer?' do
      let(:authorizable) { build(:customer_user) }

      it { is_expected.to(be(false)) }
    end
  end

  describe '#view_charges?' do
    subject { policy.apply(:view_charges?) }

    it { is_expected.to(be(true)) }

    context 'when authorizable.carrier?' do
      let(:authorizable) { build(:user, companyable: build(:broker_carrier)) }

      it { is_expected.to(be(false)) }
    end

    context 'when authorizable.customer?' do
      let(:authorizable) { build(:customer_user) }

      it { is_expected.to(be(true)) }
    end
  end

  describe '#view_costs?' do
    subject { policy.apply(:view_costs?) }

    it { is_expected.to(be(true)) }

    context 'when authorizable.carrier?' do
      let(:authorizable) { build(:user, companyable: build(:broker_carrier)) }

      it { is_expected.to(be(true)) }
    end

    context 'when authorizable.customer?' do
      let(:authorizable) { build(:customer_user) }

      it { is_expected.to(be(false)) }
    end
  end

  describe '#view_internal_notes?' do
    subject { policy.apply(:view_internal_notes?) }

    it { is_expected.to(be(true)) }

    context 'when authorizable.carrier?' do
      let(:authorizable) { build(:user, companyable: build(:broker_carrier)) }

      it { is_expected.to(be(false)) }
    end

    context 'when authorizable.customer?' do
      let(:authorizable) { build(:customer_user) }

      it { is_expected.to(be(false)) }
    end
  end

  describe '#view_shared_notes?' do
    subject { policy.apply(:view_shared_notes?) }

    it { is_expected.to(be(true)) }

    context 'when authorizable.carrier?' do
      let(:authorizable) { build(:user, companyable: build(:broker_carrier)) }

      it { is_expected.to(be(false)) }
    end

    context 'when authorizable.customer?' do
      let(:authorizable) { build(:customer_user) }

      it { is_expected.to(be(true)) }
    end
  end
end
