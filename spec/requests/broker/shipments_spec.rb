require 'rails_helper'

RSpec.describe('Broker::Shipments') do
  let(:current_user) { create(:root_broker_user).tap { |user| user.add_role(:dispatch) } }
  let(:shipment) { create(:shipment, :usd, broker_carrier: nil, load_id: 4242, quote_only: false) }

  before do
    create(:item, shipment:)
    create(:setting, key: 'customer_service_email', value: 'help@broker.test')
    create(:setting, key: 'mailing_address', value: create(:address))
    create(:setting, key: 'name', value: 'Broker Co')
    sign_in(current_user)
  end

  describe 'DELETE /broker/shipments/:load_id' do
    before { delete(broker_shipment_path(shipment)) }

    it { is_expected.to(redirect_to(broker_shipments_path)) }
    it { expect(Shipment.exists?(shipment.id)).to(be(false)) }

    context 'with a receivable' do
      let(:shipment) do
        create(:shipment, broker_carrier: nil, load_id: 4242, quote_only: false).tap do |shipment|
          build(:receivable, shipment:).save!(validate: false)
        end
      end

      it { expect(flash[:danger]).to(eq('Error deleting shipment')) }
      it { expect(Shipment.exists?(shipment.id)).to(be(true)) }
    end

    context 'without the sales rep role' do
      let(:current_user) { create(:broker_user) }

      it { is_expected.to(have_http_status(:not_found)) }
      it { expect(Shipment.exists?(shipment.id)).to(be(true)) }
    end
  end

  describe 'GET /broker/shipments/:load_id' do
    let(:alert) { Nokogiri::HTML(response.body).at_xpath('//div[contains(@class, "alert")][.//p[contains(., "Missing Services")]]') }

    before do
      seed_settings
      get(broker_shipment_path(shipment))
    end

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(alert).to(be_nil) }

    context 'with a suggested accessorial' do
      let(:broker_accessorial) { BrokerAccessorial.find_by!(code: 'DAIR') }
      let(:href) { broker_shipment_path(shipment, shipment: { shipment_broker_accessorials_attributes: }) }
      let(:shipment) do
        create(:shipment, :usd, broker_carrier: nil, dispatched_at: nil, load_id: 4242, quote_only: false, receiver_name: 'Airport').tap do
          accessorial = create(:accessorial, code: 'DAIR', name: 'Airport')
          create(:broker_accessorial, accessorial:, broker_customer: nil, code: 'DAIR', name: 'Airport')
        end
      end
      let(:shipment_broker_accessorials_attributes) { [{ broker_accessorial_id: broker_accessorial.id }] }

      it { expect(alert.at_css('a')['href']).to(eq(href)) }
      it { expect(alert.at_css('a[data-turbo-method="patch"]').text).to(eq('Add Airport')) }
    end
  end

  describe 'GET /broker/shipments/:load_id.ebol' do
    before { get(broker_shipment_path(shipment, format: :ebol)) }

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(response.media_type).to(eq('application/vnd.nmfta.ebol+json')) }
    it { expect(response.headers['Content-Disposition']).to(start_with('attachment; filename="4242.ebol.json"')) }
    it { expect(response.parsed_body).to(eq(JSON.parse(EBOL::Exporter.call(Shipment.find(shipment.id)).to_json))) }

    context 'when requested again with the ETag' do
      let(:etag) { response.headers['ETag'] }

      context 'when an address changed' do
        before do
          shipment.receiver_address.update!(street: '9 New St', updated_at: 1.minute.from_now)
          get(broker_shipment_path(shipment, format: :ebol), headers: { 'If-None-Match' => etag })
        end

        it { is_expected.to(have_http_status(:ok)) }
      end

      context 'when an item changed' do
        before do
          shipment.items.first.update!(updated_at: 1.minute.from_now, weight: 999)
          get(broker_shipment_path(shipment, format: :ebol), headers: { 'If-None-Match' => etag })
        end

        it { is_expected.to(have_http_status(:ok)) }
      end

      context 'when nothing changed' do
        before { get(broker_shipment_path(shipment, format: :ebol), headers: { 'If-None-Match' => etag }) }

        it { is_expected.to(have_http_status(:not_modified)) }
      end
    end

    context 'with a carrier' do
      let(:shipment) { create(:shipment, broker_carrier: create(:broker_carrier), load_id: 4242, quote_only: false) }

      it { is_expected.to(have_http_status(:ok)) }
    end
  end

  describe 'GET /broker/shipments/:load_id/edit' do
    before do
      seed_settings
      get(edit_broker_shipment_path(shipment))
    end

    it { is_expected.to(have_http_status(:ok)) }

    context 'when the user cannot access the shipment' do
      let(:current_user) { create(:broker_user) }

      it { is_expected.to(have_http_status(:not_found)) }
    end
  end

  describe 'GET /broker/shipments/:load_id/transit' do
    let(:reason) { Nokogiri::HTML(response.body).at_css('[data-reschedule-target="reason"]') }

    before do
      seed_settings
      get(transit_broker_shipment_path(shipment))
    end

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(reason).to(be_nil) }

    context 'when the pickup is rescheduled' do
      let(:shipment) do
        create(:shipment, broker_carrier: nil, load_id: 4242, quote_only: false).tap do |shipment|
          create(:pickup_request, accepted_pickup_on: shipment.pickup_on - 1.day, shipments: [shipment])
        end
      end

      it { expect(reason['hidden']).to(be_nil) }
    end

    context 'with a pickup request' do
      let(:shipment) do
        create(:shipment, broker_carrier: nil, load_id: 4242, quote_only: false).tap do |shipment|
          create(:pickup_request, accepted_pickup_on: shipment.pickup_on, shipments: [shipment])
        end
      end

      it { expect(reason['hidden']).to(be_present) }
    end
  end

  describe 'PATCH /broker/shipments/:load_id' do
    let(:broker_accessorial) { create(:broker_accessorial, accessorial: nil, broker_customer: nil, code: 'DAIR', name: 'Airport') }
    let(:kept) { create(:broker_accessorial, accessorial: nil, broker_customer: nil, code: 'DRES', name: 'Residential') }
    let(:shipment_broker_accessorials_attributes) { [{ broker_accessorial_id: broker_accessorial.id }] }

    before do
      shipment.shipment_broker_accessorials.create!(broker_accessorial: kept, cost: 10)
      patch(broker_shipment_path(shipment, shipment: { shipment_broker_accessorials_attributes: }))
    end

    it { is_expected.to(redirect_to(broker_shipment_path(shipment))) }
    it { expect(shipment.reload.broker_accessorials).to(contain_exactly(broker_accessorial, kept)) }
    it { expect(shipment.shipment_broker_accessorials.find_by(broker_accessorial: kept).cost).to(eq(Money.from_amount(10))) }
  end

  describe 'PATCH /broker/shipments/:load_id.json' do
    let(:delivered_at) { 1.day.ago }

    before { patch(broker_shipment_path(shipment, format: :json), params: { shipment: { delivered_at: } }) }

    it { expect(response.parsed_body).to(eq('location' => '/broker/shipments/4242')) }

    context 'when invalid' do
      let(:delivered_at) { 1.day.from_now }

      it { is_expected.to(have_http_status(:unprocessable_content)) }
      it { expect(response.parsed_body).to(eq('delivered_at' => ['cannot be in the future'])) }
    end
  end

  describe 'POST /broker/shipments' do
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
      post(broker_shipments_path, params:)
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
