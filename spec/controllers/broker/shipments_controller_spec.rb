require 'rails_helper'

RSpec.describe(Broker::ShipmentsController) do
  subject { response }

  let(:current_user) { create(:root_broker_user).tap { |user| user.add_role(:dispatch) } }
  let(:shipment) { create(:shipment, broker: current_user.companyable) }

  before { sign_in(current_user) }

  describe 'GET #history' do
    let!(:item) { create(:item, shipment:) }
    let(:older_setting) { create(:setting, key: 'name', updated_at: Time.utc(2025, 1, 1), value: 'Liftoff') }
    let(:setting) { create(:setting, key: 'time_zone_name', updated_at: Time.utc(2026, 1, 1, 0, 0, 0.1), value: 'America/Los_Angeles') }

    before do
      older_setting
      setting
      get(:history, params: { load_id: shipment.load_id })
    end

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

      context 'when the Broker changed' do
        before do
          current_user.companyable.touch(time: 1.minute.from_now)
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
end
