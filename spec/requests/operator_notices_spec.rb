require 'rails_helper'

RSpec.describe('Operator notices') do
  let(:cache) { ActiveSupport::Cache::MemoryStore.new }
  let(:notice) { { 'message' => 'Please call us', 'status' => 'past_due' } }

  before do
    allow(OFREP).to(receive(:configured?).and_return(true))
    allow(Rails).to(receive(:cache).and_return(cache))
    seed_settings
  end

  context 'with a broker user' do
    let(:current_user) { create(:root_broker_user) }
    let(:shipment) { create(:shipment, broker_carrier: nil, quote_only: false).tap { |shipment| create(:item, shipment:) } }

    before do
      sign_in(current_user)
      get(broker_shipments_path)
    end

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(response.body).not_to(include('Please call us')) }

    context 'when a notice appears after the first request' do
      before do
        etag = response.headers['ETag']
        cache.write('operator_notice', notice)
        get(broker_shipments_path, headers: { 'If-None-Match' => etag })
      end

      it { is_expected.to(have_http_status(:ok)) }
      it { expect(response.body).to(include('Please call us')) }
      it { expect(response.body).not_to(include('application owner')) }
    end

    context 'when the notice is enforced' do
      before do
        cache.write('operator_notice', notice.merge('status' => 'suspended'))
        get(broker_shipments_path)
      end

      it { is_expected.to(have_http_status(:service_unavailable)) }
      it { expect(response.body).to(include('temporarily unavailable')) }
      it { expect(response.body).not_to(include('Please call us', 'application owner')) }
    end

    context 'when the notice is enforced for a non-HTML request' do
      before do
        cache.write('operator_notice', notice.merge('status' => 'suspended'))
        get(broker_shipments_path(format: :json))
      end

      it { is_expected.to(have_http_status(:service_unavailable)) }
    end

    context 'when the notice is enforced for a write' do
      before do
        cache.write('operator_notice', notice.merge('status' => 'suspended'))
        delete(broker_shipment_path(shipment))
      end

      it { is_expected.to(have_http_status(:service_unavailable)) }
      it { expect(Shipment.exists?(shipment.id)).to(be(true)) }
    end
  end

  context 'with a carrier user' do
    let(:broker_carrier) { create(:broker_carrier) }

    before do
      cache.write('operator_notice', notice.merge('status' => 'suspended'))
      sign_in(create(:carrier_user, companyable: broker_carrier.carrier))
      get("/carrier/#{broker_carrier.id}/shipments")
    end

    it { is_expected.to(have_http_status(:service_unavailable)) }
    it { expect(response.body).to(include('temporarily unavailable')) }
    it { expect(response.body).not_to(include('Please call us', 'application owner')) }
  end

  context 'with a customer user' do
    before do
      cache.write('operator_notice', notice.merge('status' => 'suspended'))
      sign_in(create(:customer_user))
      get(customer_shipments_path)
    end

    it { is_expected.to(have_http_status(:service_unavailable)) }
    it { expect(response.body).to(include('temporarily unavailable')) }
    it { expect(response.body).not_to(include('Please call us', 'application owner')) }
  end

  context 'with a signed out user' do
    before do
      cache.write('operator_notice', notice.merge('status' => 'suspended'))
      get(root_path)
    end

    it { is_expected.to(have_http_status(:service_unavailable)) }
    it { expect(response.body).to(include('temporarily unavailable')) }
    it { expect(response.body).not_to(include('Please call us', 'application owner')) }
  end
end
