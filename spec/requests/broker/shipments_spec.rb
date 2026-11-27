require 'rails_helper'

RSpec.describe('Broker::Shipments') do
  let(:current_user) { create(:root_broker_user).tap { |user| user.add_role(:dispatch) } }
  let(:shipment) { create(:shipment, :usd, broker_carrier: nil, load_id: 4242, quote_only: false) }

  before do
    create(:item, shipment:)
    create(:setting, key: 'mailing_address', value: create(:address))
    seed_settings
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

    before { get(broker_shipment_path(shipment)) }

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(alert).to(be_nil) }

    context 'with a suggested accessorial' do
      let(:href) do
        broker_shipment_path(shipment, shipment: { shipment_accessorials_attributes: [{ accessorial_key: 'airport_delivery' }] })
      end
      let(:receiver_address) { build(:address, name: 'Airport') }
      let(:shipment) do
        create(:shipment, :usd, broker_carrier: nil, dispatched_at: nil, load_id: 4242, quote_only: false, receiver_address:)
      end

      it { expect(alert.at_css('a')['href']).to(eq(href)) }
      it { expect(alert.at_css('a[data-turbo-method="patch"]').text).to(eq('Add Airport Delivery')) }

      context 'when the broker renamed the accessorial' do
        let(:accessorial) { Accessorial.find_by!(code: 'DAIR') }
        let(:href) do
          broker_shipment_path(shipment, shipment: { shipment_accessorials_attributes: [{ accessorial_key: accessorial.key }] })
        end
        let(:shipment) do
          create(:shipment, :usd, broker_carrier: nil, dispatched_at: nil, load_id: 4242, quote_only: false, receiver_address:).tap do
            create(:accessorial, code: 'DAIR', name: 'Airport', transponder_code: 'airport_delivery')
          end
        end

        it { expect(alert.at_css('a')['href']).to(eq(href)) }
        it { expect(alert.at_css('a[data-turbo-method="patch"]').text).to(eq('Add Airport')) }
      end
    end
  end

  describe 'GET /broker/shipments/:load_id/documents' do
    before do
      ActiveJob::Base.queue_adapter.enqueued_jobs.clear
      get(documents_broker_shipment_path(shipment))
    end

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(DocumentableService::Shipment::CreateBrokerEBOLJob).not_to(have_been_enqueued) }

    context 'with a carrier' do
      let(:shipment) { create(:shipment, :usd, broker_carrier: create(:broker_carrier), load_id: 4242, quote_only: false) }

      it { expect(DocumentableService::Shipment::CreateBrokerEBOLJob).to(have_been_enqueued.with(shipment)) }
    end
  end

  describe 'GET /broker/shipments/:load_id/edit' do
    before { get(edit_broker_shipment_path(shipment)) }

    it { is_expected.to(have_http_status(:ok)) }

    context 'when the user cannot access the shipment' do
      let(:current_user) { create(:broker_user) }

      it { is_expected.to(have_http_status(:not_found)) }
    end
  end

  describe 'GET /broker/shipments/:load_id/history' do
    let(:text) { Nokogiri::HTML(response.body).at_css('h2 + .table-responsive tbody').text.squish }

    before do
      shipment.shipper_address.update!(name: 'Acme Freight')
      get(history_broker_shipment_path(shipment))
    end

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(text).to(include('Shipper address updated')) }
    it { expect(text).to(include('"Acme Freight"')) }
  end

  describe 'GET /broker/shipments/:load_id/transit' do
    let(:reason) { Nokogiri::HTML(response.body).at_css('[data-reschedule-target="reason"]') }

    before { get(transit_broker_shipment_path(shipment)) }

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
    let(:accessorial) { create(:accessorial, broker_customer: nil, code: 'DAIR', name: 'Airport') }
    let(:accessorial_key) { accessorial.key }
    let(:kept) { create(:accessorial, broker_customer: nil, code: 'DRES', name: 'Residential') }
    let(:shipment_accessorials_attributes) { [{ accessorial_key: }] }

    before do
      shipment.shipment_accessorials.create!(accessorial: kept, cost: 10)
      patch(broker_shipment_path(shipment, shipment: { shipment_accessorials_attributes: }))
    end

    it { is_expected.to(redirect_to(broker_shipment_path(shipment))) }
    it { expect(shipment.reload.accessorials).to(contain_exactly(accessorial, kept)) }
    it { expect(shipment.shipment_accessorials.find_by(accessorial: kept).cost).to(eq(Money.from_amount(10))) }

    context 'with a Transponder accessorial' do
      let(:accessorial_key) { 'airport_delivery' }

      it { expect(shipment.reload.accessorials.map(&:transponder_code)).to(contain_exactly('airport_delivery', nil)) }

      it do
        expect(Accessorial.find_by(transponder_code: 'airport_delivery')).to(have_attributes(broker_only: false, name: 'Airport Delivery'))
      end
    end
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
      create(:accessorial, broker_customer: nil, code: 'DAIR', name: 'Airport', transponder_code: 'airport_delivery')
      post(broker_shipments_path, params:)
    end

    it { is_expected.to(have_http_status(:unprocessable_content)) }
    it { expect(document.at_css('.alert-info').text.squish).to(be_present) }
    it { expect(document.at_css('input[name="shipment[accessorials_has_been_suggested]"]')['value']).to(eq('true')) }
    it { expect(document.at_css('select[name$="[accessorial_key]"] option[selected]').text).to(eq('Airport')) }

    context 'when accessorials were already suggested' do
      let(:accessorials_has_been_suggested) { 'true' }

      it { expect(document.at_css('.alert-info')).to(be_nil) }
    end
  end
end
