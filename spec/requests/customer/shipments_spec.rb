require 'rails_helper'

RSpec.describe('Customer::Shipments') do
  let(:current_user) { create(:customer_user) }
  let(:shipment) { create(:shipment, broker_carrier: nil, broker_customer: current_user.companyable, load_id: 4343, quote_only: false) }

  before do
    create(:item, shipment:)
    seed_settings
    sign_in(current_user)
  end

  describe 'GET /customer/shipments/:load_id/documents' do
    before do
      ActiveJob::Base.queue_adapter.enqueued_jobs.clear
      get(documents_customer_shipment_path(shipment))
    end

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(DocumentableService::Shipment::CreateBrokerEBOLJob).not_to(have_been_enqueued) }

    context 'with a carrier' do
      let(:shipment) do
        create(
          :shipment,
          broker_carrier: create(:broker_carrier),
          broker_customer: current_user.companyable,
          load_id: 4343,
          quote_only: false
        )
      end

      it { expect(DocumentableService::Shipment::CreateBrokerEBOLJob).to(have_been_enqueued.with(shipment)) }
    end
  end

  describe 'GET /customer/shipments/new' do
    let(:document) { Nokogiri::HTML(response.body) }
    let(:shipper_name) { document.at_css('input[name="shipment[shipper_address_attributes][name]"]')['value'] }

    before { get(new_customer_shipment_path) }

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(shipper_name).to(eq(current_user.companyable.customer.name)) }
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
          receiver_address_attributes: address.merge(name: 'Airport'),
          shipper_address_attributes: address.merge(name: 'Acme')
        }
      }
    end

    before do
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
