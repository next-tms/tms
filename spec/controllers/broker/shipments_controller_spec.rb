require 'rails_helper'

RSpec.describe(Broker::ShipmentsController) do
  subject { response }

  let(:headers) { ExporterService.new(Shipment.none, authorizable: user).headers }
  let!(:setting) { create(:setting, key: 'time_zone_name', value: 'America/Los_Angeles') }
  let(:shipment) { create(:shipment) }
  let(:user) { create(:root_broker_user) }

  before { sign_in(user) }

  %i[
    as_dispatcher
    booked
    delivered
    index
    missing_delivery_appointment
    missing_pricing
    missing_pro
    pending_delivery
    pending_departure
    pending_dispatch
    pending_found
    pending_pickup
    pending_quotation
  ].each do |action|
    describe "GET ##{action}" do
      context 'when CSV' do
        before { get(action, format: :csv) }

        it { is_expected.to(have_http_status(:ok)) }
        it { expect(response.media_type).to(eq('text/csv')) }
        it { expect(CSV.parse(response.body).first).to(eq(headers)) }
      end

      context 'when YAML' do
        before { get(action, format: :yaml) }

        it { is_expected.to(have_http_status(:ok)) }
        it { expect(response.media_type).to(eq('application/x-yaml')) }
      end

      context 'when HTML' do
        before { get(action) }

        it { is_expected.to(have_http_status(:ok)) }
      end
    end
  end

  describe 'GET #history' do
    let!(:item) { create(:item, shipment:) }
    let!(:older_setting) { create(:setting, key: 'name', updated_at: Time.utc(2025, 1, 1), value: 'Liftoff') }
    let!(:setting) { create(:setting, key: 'time_zone_name', updated_at: Time.utc(2026, 1, 1, 0, 0, 0.1), value: 'America/Los_Angeles') }
    let(:user) { create(:root_broker_user).tap { |user| user.add_role(:dispatch) } }

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
          user.update!(time_zone_name: 'America/Denver', updated_at: 1.minute.from_now)
          sign_in(user)
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

  describe 'GET #show' do
    before { get(:show, params: { load_id: shipment.load_id }) }

    it { is_expected.to(have_http_status(:ok)) }

    context 'without access to the shipment' do
      let(:user) { create(:broker_user) }

      it { is_expected.to(have_http_status(:not_found)) }
    end
  end

  describe 'GET #index with a search' do
    before do
      create(:shipment)
      get(:index, format: :csv, params: { q: { Shipment::SEARCH_PREDICATE => shipment.shipper_name } })
    end

    it { expect(CSV.parse(response.body, headers: true).pluck('Load')).to(eq([ shipment.load_id.to_s ])) }
  end
end
