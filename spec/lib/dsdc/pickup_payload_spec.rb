require 'rails_helper'

RSpec.describe(DSDC::PickupPayload) do
  subject(:payload) { described_class.new(params, pickup_request:, user:) }

  let(:body) { JSON.parse(file_fixture('dsdc/pickup_request.json').read.sub('PRO_NUMBER', shipment.load_id.to_s)) }
  let(:params) { ActionController::Parameters.new(body).permit(described_class::PERMITTED) }
  let(:pickup_request) { PickupRequest.new(created_by: user) }
  let(:shipment) { create(:shipment, :usd, broker_customer: user.companyable, picked_up_at: nil) }
  let(:user) { create(:customer_user) }

  describe '#closes_after_ready?' do
    it { is_expected.to(be_closes_after_ready) }

    context 'when the close time is before the ready time' do
      before { body['closeTime'] = '2026-11-02T08:00:00-08:00' }

      it { is_expected.not_to(be_closes_after_ready) }
    end
  end

  describe '#closes_at' do
    it { expect(payload.closes_at).to(eq(Time.new(2026, 11, 2, 16, 30, 0, '-08:00'))) }
  end

  describe '#pickup_request_attributes' do
    it { expect(payload.pickup_request_attributes).to(eq(accepted_pickup_on: Date.new(2026, 11, 2), reschedule_reason: nil)) }
  end

  describe '#pro_numbers' do
    it { expect(payload.pro_numbers).to(eq([shipment.load_id.to_s])) }
  end

  describe '#ready_at' do
    it { expect(payload.ready_at).to(eq(Time.new(2026, 11, 2, 9, 0, 0, '-08:00'))) }

    context 'without a ready time' do
      before { body.merge!('readyDate' => '2026-11-03T08:00:00-08:00', 'readyTime' => '') }

      it { expect(payload.ready_at).to(eq(Time.new(2026, 11, 3, 8, 0, 0, '-08:00'))) }
    end
  end

  describe '#save' do
    before { payload.save }

    it { expect(pickup_request).to(be_persisted) }
    it { expect(shipment.reload).to(have_attributes(pickup_on: Date.new(2026, 11, 2), pickup_request:, updated_by: user)) }

    context 'when a shipment is removed' do
      let(:pickup_request) { create(:pickup_request, created_by: user, shipments: [removed_shipment]) }
      let(:removed_shipment) { create(:shipment, :usd, broker_customer: user.companyable, picked_up_at: nil) }

      it { expect(removed_shipment.reload.pickup_request).to(be_nil) }
    end

    context 'when the payload is invalid' do
      let(:body) { super().merge('shipmentDetails' => []) }

      it { expect(payload.save).to(be(false)) }
      it { expect(pickup_request).not_to(be_persisted) }
    end
  end

  describe '#shipment_attributes' do
    it do
      expect(payload.shipment_attributes).to(eq(pickup_hours_end_at: '4:30 PM', pickup_hours_start_at: '9:00 AM',
                                                pickup_on: Date.new(2026, 11, 2)))
    end
  end

  describe '#shipments' do
    it { expect(payload.shipments).to(eq([shipment])) }
  end

  describe '#test?' do
    it { is_expected.not_to(be_test) }

    context 'when isTest is True' do
      before { body['isTest'] = 'True' }

      it { is_expected.to(be_test) }
    end
  end

  describe '#valid?' do
    it { is_expected.to(be_valid) }

    context 'when the close time is before the ready time' do
      before { body['closeTime'] = '2026-11-02T08:00:00-08:00' }

      it { is_expected.not_to(be_valid) }
    end

    context 'when the shipment belongs to a canceled pickup request' do
      before { create(:pickup_request, canceled_at: Time.current, shipments: [shipment]) }

      it { is_expected.to(be_valid) }
    end

    context 'when the shipment belongs to another pickup request' do
      before { create(:pickup_request, shipments: [shipment]) }

      it { is_expected.not_to(be_valid) }
    end

    context 'when the shipment was picked up' do
      let(:shipment) { create(:shipment, :usd, broker_customer: user.companyable) }

      it { is_expected.not_to(be_valid) }
    end

    context 'without PRO numbers' do
      before { body['shipmentDetails'] = [] }

      it { is_expected.not_to(be_valid) }
    end
  end
end
