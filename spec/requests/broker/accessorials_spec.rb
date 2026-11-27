require 'rails_helper'

RSpec.describe('Broker::Accessorials') do
  subject { response }

  let(:broker_customer) { create(:broker_customer) }

  before do
    seed_settings
    sign_in(create(:root_broker_user))
  end

  describe 'GET /broker/settings/company/accessorials' do
    before do
      create(:accessorial, name: 'Appointment Delivery')
      create(:accessorial, broker_customer:, name: 'Curbside')
      create(:accessorial, name: 'Weekend Holding')
      get('/broker/settings/company/accessorials', params:)
    end

    context 'without params' do
      let(:params) { {} }

      it { is_expected.to(have_http_status(:ok)) }
      it { expect(response.body).to(include(ERB::Util.html_escape(broker_customer.name))) }
      it { expect(response.body.index('Appointment Delivery')).to(be < response.body.index('Weekend Holding')) }
    end

    context 'when sorting by name descending' do
      let(:params) { { q: { s: 'name desc' } } }

      it { is_expected.to(have_http_status(:ok)) }
      it { expect(response.body.index('Weekend Holding')).to(be < response.body.index('Appointment Delivery')) }
    end

    context 'when the request repeats the ETag' do
      let(:params) { {} }

      before { get('/broker/settings/company/accessorials', headers: { 'If-None-Match' => response.headers['ETag'] }) }

      it { is_expected.to(have_http_status(:not_modified)) }
    end

    context 'when the customer is renamed after the ETag' do
      let(:params) { {} }

      before do
        etag = response.headers['ETag']
        broker_customer.customer.update!(name: 'Renamed Customer')
        get('/broker/settings/company/accessorials', headers: { 'If-None-Match' => etag })
      end

      it { is_expected.to(have_http_status(:ok)) }
    end
  end
end
