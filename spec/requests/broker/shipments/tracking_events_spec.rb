require 'rails_helper'

RSpec.describe('Broker::Shipments::TrackingEvents') do
  let(:current_user) { create(:root_broker_user).tap { |user| user.add_role(:dispatch) } }
  let(:path) { "/broker/shipments/#{shipment.load_id}/tracking" }
  let(:shipment) { create(:shipment) }
  let(:tracking_event) { create(:tracking_event, shipment:) }

  before do
    create(:setting, key: 'mailing_address', value: create(:address))
    seed_settings
    sign_in(current_user)
  end

  describe 'GET /broker/shipments/:shipment_load_id/tracking' do
    before { get(path) }

    it { is_expected.to(have_http_status(:ok)) }
  end

  describe 'GET /broker/shipments/:shipment_load_id/tracking/edit' do
    before { get("#{path}/edit") }

    it { is_expected.to(have_http_status(:ok)) }
  end

  describe 'PATCH /broker/shipments/:shipment_load_id/tracking' do
    let(:params) { { tracking_events: [{ _destroy: '1', id: tracking_event.id }] } }

    before { patch(path, params:) }

    it { is_expected.to(redirect_to(path)) }
    it { expect(TrackingEvent).not_to(exist(tracking_event.id)) }

    context 'when the user cannot access the shipment' do
      let(:current_user) { create(:broker_user) }

      it { is_expected.to(have_http_status(:not_found)) }
    end
  end
end
