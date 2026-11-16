require 'rails_helper'

RSpec.describe('Notifications') do
  subject { response }

  let(:current_user) { create(:root_broker_user) }
  let(:event) { ShipmentNotifier.with(attribute_changed: :new_shipment, shipment:).deliver(current_user, enqueue_job: false) }
  let(:notification) { event.notifications.first }
  let(:shipment) { create(:shipment) }

  before do
    seed_settings
    sign_in(current_user)
  end

  describe 'GET /notifications' do
    before do
      notification
      get(notifications_path, params:)
    end

    context 'with a filter that does not match' do
      let(:params) { { q: { params_cont: 'no such load' } } }

      it { is_expected.to(have_http_status(:ok)) }
      it { expect(response.body).not_to(include(event.message)) }
    end

    context 'with a filter that matches' do
      let(:params) { { q: { params_cont: shipment.load_id.to_s } } }

      it { is_expected.to(have_http_status(:ok)) }
      it { expect(response.body).to(include(event.message)) }
    end

    context 'with a matching ETag' do
      let(:params) { {} }

      before { get(notifications_path, headers: { 'If-None-Match' => response.headers['ETag'] }) }

      it { is_expected.to(have_http_status(:not_modified)) }
    end

    context 'without a filter' do
      let(:params) { {} }

      it { is_expected.to(have_http_status(:ok)) }
      it { expect(response.body).to(include(event.message)) }
    end
  end

  describe 'GET /notifications/:id' do
    context 'with a matching ETag' do
      before do
        get(notification_path(notification))
        get(notification_path(notification), headers: { 'If-None-Match' => response.headers['ETag'] })
      end

      it { is_expected.to(have_http_status(:not_modified)) }
    end

    context 'with a notification of another user' do
      let(:event) { ShipmentNotifier.with(attribute_changed: :new_shipment, shipment:).deliver(create(:broker_user), enqueue_job: false) }

      before { get(notification_path(notification)) }

      it { is_expected.to(have_http_status(:not_found)) }
    end

    context 'with a notification of the current user' do
      before { get(notification_path(notification)) }

      it { is_expected.to(have_http_status(:ok)) }
      it { expect(response.body).to(include(event.notification_subject)) }
      it { expect(notification.reload).to(be_read) }
    end
  end
end
