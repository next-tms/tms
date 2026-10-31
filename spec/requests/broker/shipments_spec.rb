require 'rails_helper'

RSpec.describe('Broker::Shipments') do
  subject { response }

  let(:current_user) { create(:root_broker_user).tap { |user| user.add_role(:dispatch) } }
  let(:shipment) { create(:shipment, broker_carrier: nil, load_id: 4242, quote_only: false) }

  before do
    create(:item, shipment:)
    create(:setting, key: 'customer_service_email', value: 'help@broker.test')
    create(:setting, key: 'mailing_address', value: create(:address))
    create(:setting, key: 'name', value: 'Broker Co')
    sign_in(current_user)
  end

  describe 'GET /broker/shipments/:load_id.ebol' do
    before { get(broker_shipment_path(shipment, format: :ebol)) }

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(response.media_type).to(eq('application/vnd.nmfta.ebol+json')) }
    it { expect(response.headers['Content-Disposition']).to(start_with('attachment; filename="4242.ebol.json"')) }
    it { expect(JSON.parse(response.body)).to(eq(JSON.parse(EBOL.call(Shipment.find(shipment.id)).to_json))) }

    context 'with a carrier' do
      let(:shipment) { create(:shipment, broker_carrier: create(:broker_carrier), load_id: 4242, quote_only: false) }

      it { is_expected.to(have_http_status(:ok)) }
    end

    context 'when requested again with the ETag' do
      let(:etag) { response.headers['ETag'] }

      context 'when nothing changed' do
        before { get(broker_shipment_path(shipment, format: :ebol), headers: { 'If-None-Match' => etag }) }

        it { is_expected.to(have_http_status(:not_modified)) }
      end

      context 'when an item changed' do
        before do
          shipment.items.first.update!(updated_at: 1.minute.from_now, weight: 999)
          get(broker_shipment_path(shipment, format: :ebol), headers: { 'If-None-Match' => etag })
        end

        it { is_expected.to(have_http_status(:ok)) }
      end

      context 'when an address changed' do
        before do
          shipment.receiver_address.update_columns(street: '9 New St', updated_at: 1.minute.from_now)
          get(broker_shipment_path(shipment, format: :ebol), headers: { 'If-None-Match' => etag })
        end

        it { is_expected.to(have_http_status(:ok)) }
      end
    end
  end
end
