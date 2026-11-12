require 'rails_helper'

RSpec.describe('Customer::Shipments') do
  let(:current_user) { create(:customer_user) }
  let(:shipment) { create(:shipment, broker_carrier: nil, broker_customer: current_user.companyable, load_id: 4343, quote_only: false) }

  before do
    create(:item, shipment:)
    create(:setting, key: 'customer_service_email', value: 'help@broker.test')
    create(:setting, key: 'mailing_address', value: create(:address))
    create(:setting, key: 'name', value: 'Broker Co')
    sign_in(current_user)
  end

  describe 'GET /customer/shipments/:load_id.ebol' do
    before { get(customer_shipment_path(shipment, format: :ebol)) }

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(response.media_type).to(eq('application/vnd.nmfta.ebol+json')) }
    it { expect(response.headers['Content-Disposition']).to(start_with('attachment; filename="4343.ebol.json"')) }
    it { expect(response.parsed_body).to(eq(JSON.parse(EBOL::Exporter.call(Shipment.find(shipment.id)).to_json))) }

    context 'with a carrier' do
      let(:shipment) do
        create(:shipment, broker_carrier: create(:broker_carrier), broker_customer: current_user.companyable, load_id: 4343,
                          quote_only: false)
      end

      it { is_expected.to(have_http_status(:ok)) }
    end

    context 'when requested again with the ETag' do
      before { get(customer_shipment_path(shipment, format: :ebol), headers: { 'If-None-Match' => response.headers['ETag'] }) }

      it { is_expected.to(have_http_status(:not_modified)) }
    end

    context "with another customer's shipment" do
      let(:shipment) { create(:shipment, broker_carrier: nil, load_id: 4343, quote_only: false) }

      it { is_expected.to(have_http_status(:not_found)) }
    end
  end

  describe 'PATCH /customer/shipments/:load_id.json' do
    before { patch(customer_shipment_path(shipment, format: :json), params: { shipment: { customer_reference: 'ABC123' } }) }

    it { expect(response.parsed_body).to(eq('location' => '/customer/shipments/4343')) }
  end

  describe 'POST /customer/shipments' do
    let(:accessorial) { create(:accessorial, code: 'DAIR', name: 'Airport') }
    let(:accessorials_has_been_suggested) { nil }
    let(:address) { { city: 'Reno', country_alpha2: 'US', zip_code: '89501' } }
    let(:document) { Nokogiri::HTML(response.body) }
    let(:params) do
      {
        shipment: {
          accessorials_has_been_suggested:,
          items_attributes: [{ desc: 'Box', quantity: 1, weight: 100 }],
          quote_only: false,
          receiver_address_attributes: address,
          receiver_name: 'Airport',
          shipper_address_attributes: address,
          shipper_name: 'Acme'
        }
      }
    end

    before do
      seed_settings
      create(:broker_accessorial, accessorial:, broker_customer: nil, code: 'DAIR', name: 'Airport')
      post(customer_shipments_path, params:)
    end

    it { is_expected.to(have_http_status(:unprocessable_content)) }
    it { expect(document.at_css('.alert-info').text.squish).to(be_present) }
    it { expect(document.at_css('input[name="shipment[accessorials_has_been_suggested]"]')['value']).to(eq('true')) }
    it { expect(document.at_css('select[name$="[broker_accessorial_id]"] option[selected]').text).to(eq('Airport')) }

    context 'when accessorials were already suggested' do
      let(:accessorials_has_been_suggested) { 'true' }

      it { expect(document.at_css('.alert-info')).to(be_nil) }
    end
  end
end
