require 'rails_helper'

RSpec.describe Shipment, type: :model do
  describe 'relationships' do
    it { is_expected.to have_many(:tracking_events) }
    it { is_expected.to have_many(:commissions) }
    it { is_expected.to have_many(:problems) }
    it { is_expected.to have_many(:pickups) }
    it { is_expected.to have_many(:rates) }
    it { is_expected.to have_many(:shipment_items) }
    it { is_expected.to have_many(:items).through(:shipment_items) }
    it { is_expected.to have_many(:payment_transactions) }
    it { is_expected.to have_many(:payments).through(:payment_transactions) }
    it { is_expected.to have_many(:shipment_accessorials) }
    it { is_expected.to have_many(:accessorials).through(:shipment_accessorials) }

    it { is_expected.to belong_to(:broker) }
    it { is_expected.to belong_to(:broker_carrier).required(false) }
    it { is_expected.to belong_to(:broker_customer).required(false) }
    it { is_expected.to belong_to(:tracking_carrier).required(false) }
    it { is_expected.to belong_to(:receiver_address) }
    it { is_expected.to belong_to(:shipper_address) }
    it { is_expected.to belong_to(:applied_rate).required(false) }
  end

  describe 'audits' do
    context 'when shipment is created' do
      let(:shipment) { build(:shipment) }

      it 'creates an audit record' do
        expect { shipment.save }.to change { shipment.audits.count }.by(1)
        audit = shipment.reload.audits.last

        expect(audit.action).to eq('create')
      end
    end

    context 'when shipment is updated' do
      let!(:shipment) { create(:shipment) }

      it 'creates an audit record' do
        expect { shipment.update(receiver_name: 'Test') }.to change { shipment.audits.count }.by(1)
        audit = shipment.reload.audits.last

        expected_audit_change = { 'receiver_name' => ['MyString', 'Test'] }
        expect(audit.action).to eq('update')
        expect(audit.audited_changes).to eq(expected_audit_change)
      end
    end
  end
end