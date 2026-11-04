require 'rails_helper'

RSpec.describe('Carrier::Shipments') do
  let(:broker_carrier) { create(:broker_carrier) }
  let(:current_user) { create(:carrier_user, companyable: broker_carrier.carrier) }
  let(:other_account) { create(:broker_carrier, broker_customer: create(:broker_customer), carrier: broker_carrier.carrier) }
  let!(:shipment) { create(:shipment, broker_carrier:, pro: 'MINE-1', total_charges_cents: 98_765) }

  before do
    seed_settings
    create(:shipment, broker_carrier: other_account, pro: 'OTHER-ACCOUNT-1')
    create(:shipment, pro: 'OTHER-CARRIER-1')
    sign_in(current_user)
  end

  describe 'GET /carrier/:broker_carrier_id/shipments' do
    before { get("/carrier/#{broker_carrier.id}/shipments") }

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(assigns(:shipments)).to(contain_exactly(shipment)) }
    it { expect(response.body).to(include('MINE-1')) }
    it { expect(response.body).not_to(include('OTHER-ACCOUNT-1', '987.65')) }
    it { expect(response.body).to(include("/carrier/#{other_account.id}/shipments")) }

    context 'when an address changes after the first request' do
      before do
        etag = response.headers['ETag']
        shipment.shipper_address.update!(city: 'Elsewhere', updated_at: 1.minute.from_now)
        get("/carrier/#{broker_carrier.id}/shipments", headers: { 'If-None-Match' => etag })
      end

      it { is_expected.to(have_http_status(:ok)) }
      it { expect(response.body).to(include('Elsewhere')) }
    end

    context "when an account's customer is renamed after the first request" do
      before do
        etag = response.headers['ETag']
        other_account.broker_customer.customer.update!(name: 'Renamed Customer', updated_at: 1.minute.from_now)
        get("/carrier/#{broker_carrier.id}/shipments", headers: { 'If-None-Match' => etag })
      end

      it { is_expected.to(have_http_status(:ok)) }
      it { expect(response.body).to(include('Renamed Customer')) }
    end

    context "with another carrier's account" do
      before { get("/carrier/#{create(:broker_carrier).id}/shipments") }

      it { is_expected.to(have_http_status(:not_found)) }
    end
  end
end
