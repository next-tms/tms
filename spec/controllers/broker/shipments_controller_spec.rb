require 'rails_helper'

RSpec.describe(Broker::ShipmentsController) do
  let(:current_user) { create(:root_broker_user).tap { |user| user.add_role(:dispatch) } }
  let(:shipment) { create(:shipment) }

  before { sign_in(current_user) }

  describe '#shipment_params' do
    subject { controller.__send__(:shipment_params).to_h }

    let(:attributes) do
      {
        items_attributes: { '0' => { quantity: '2', weight: '100' } },
        pickup_request_attributes: { reschedule_reason: 'weather' },
        receiver_address_attributes: { city: 'Portland' }
      }
    end

    before { controller.params = { shipment: attributes } }

    it { is_expected.to(eq(attributes.deep_stringify_keys)) }
  end

  describe 'GET #history' do
    let!(:item) { create(:item, shipment:) }
    let!(:older_setting) { create(:setting, key: 'name', updated_at: Time.utc(2025, 1, 1), value: 'Liftoff') }
    let!(:setting) { create(:setting, key: 'time_zone_name', updated_at: Time.utc(2026, 1, 1, 0, 0, 0.1), value: 'America/Los_Angeles') }

    before { get(:history, params: { load_id: shipment.load_id }) }

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(assigns(:audits)).to(include(*shipment.audits)) }
    it { expect(assigns(:audits)).to(include(*item.audits)) }
    it { expect(assigns(:audits).map(&:created_at)).to(eq(assigns(:audits).map(&:created_at).sort.reverse)) }

    context 'when requested again with the ETag' do
      before { request.headers['If-None-Match'] = response.headers['ETag'] }

      context 'when nothing changed' do
        before { get(:history, params: { load_id: shipment.load_id }) }

        it { is_expected.to(have_http_status(:not_modified)) }
      end

      context 'when a Setting changed' do
        before do
          setting.update!(value: 'America/Denver', updated_at: 1.minute.from_now)
          get(:history, params: { load_id: shipment.load_id })
        end

        it { is_expected.to(have_http_status(:ok)) }
      end

      context 'when a Setting changed within the same second' do
        before do
          setting.update!(value: 'America/Denver', updated_at: Time.utc(2026, 1, 1, 0, 0, 0.2))
          get(:history, params: { load_id: shipment.load_id })
        end

        it { is_expected.to(have_http_status(:ok)) }
      end

      context 'when a Setting was destroyed' do
        before do
          older_setting.destroy!
          get(:history, params: { load_id: shipment.load_id })
        end

        it { is_expected.to(have_http_status(:ok)) }
      end

      context 'when current_user changed' do
        before do
          current_user.update!(time_zone_name: 'America/Denver', updated_at: 1.minute.from_now)
          sign_in(current_user)
          get(:history, params: { load_id: shipment.load_id })
        end

        it { is_expected.to(have_http_status(:ok)) }
      end
    end
  end

  %i[
    booked
    delivered
    missing_delivery_appointment
    pending_delivery
    pending_departure
    pending_dispatch
    pending_pickup
    pending_quotation
  ].each do |action|
    describe "GET ##{action}" do
      before { get(action) }

      it { is_expected.to(have_http_status(:ok)) }
      it { expect(unknown_includes(Shipment, assigns(:shipments).includes_values)).to(be_empty) }
    end
  end

  describe 'PATCH #upload_document' do
    let(:document) { fixture_file_upload('pod.pdf', 'application/pdf') }

    before { patch(:upload_document, params: { load_id: shipment.load_id, shipment: { document:, document_type: 'carrier_pod' } }) }

    it { is_expected.to(redirect_to(documents_broker_shipment_path(shipment))) }
    it { expect(shipment.reload.carrier_pod).to(be_attached) }
  end
end
