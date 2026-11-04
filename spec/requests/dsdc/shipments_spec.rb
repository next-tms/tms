require 'rails_helper'

RSpec.describe('DSDC::Shipments') do
  let(:api_key) { create(:api_key) }
  let(:headers) { { 'X-API-Key' => api_key.token } }
  let(:json) { response.parsed_body }
  let!(:shipment) { create(:shipment, broker_customer: api_key.user.companyable, bol: '1001', customer_reference: '2002') }

  describe 'GET /api/dsdc/shipment/pro/:pro/verified' do
    context 'when the shipment belongs to the API key user' do
      before { get("/api/dsdc/shipment/pro/#{shipment.load_id}/verified", headers:) }

      it { expect(response).to(have_http_status(:ok)) }
      it { expect(json).to(include('ProNumber' => shipment.load_id.to_s, 'ShipmentMilestoneStatus' => 'Delivered')) }
      it { expect(json['ReferenceNumbers']).to(include('bolNumber' => '1001', 'poNumber' => '2002')) }
      it { expect(json['ConsigneeAddress']).to(include('city' => shipment.receiver_address.city)) }
      it { expect(response.headers['ETag']).to(be_present) }
      it { expect(response.headers['Last-Modified']).to(be_present) }
    end

    context 'when a carrier changed after the shipment' do
      let!(:shipment) do
        create(
          :shipment,
          bol: '1001',
          broker_customer: api_key.user.companyable,
          customer_reference: '2002',
          tracking_carrier: create(:carrier, updated_at: 1.day.from_now)
        )
      end

      before { get("/api/dsdc/shipment/pro/#{shipment.load_id}/verified", headers:) }

      it { expect(response.headers['Last-Modified']).to(eq(shipment.tracking_carrier.updated_at.httpdate)) }
    end

    context 'when an address changed after the shipment' do
      let!(:shipment) do
        create(
          :shipment,
          bol: '1001',
          broker_customer: api_key.user.companyable,
          customer_reference: '2002',
          receiver_address: create(:address, updated_at: 1.day.from_now)
        )
      end

      before { get("/api/dsdc/shipment/pro/#{shipment.load_id}/verified", headers:) }

      it { expect(response.headers['Last-Modified']).to(eq(shipment.receiver_address.updated_at.httpdate)) }
    end

    context 'when an item changed after the shipment' do
      let(:item) { create(:item, shipment:, updated_at: 1.day.from_now) }

      before do
        item
        get("/api/dsdc/shipment/pro/#{shipment.load_id}/verified", headers:)
      end

      it { expect(response.headers['Last-Modified']).to(eq(item.updated_at.httpdate)) }
    end

    context 'when the customer changed after the shipment' do
      let(:customer) { api_key.user.companyable.customer }

      before do
        customer.update!(updated_at: 1.day.from_now)
        get("/api/dsdc/shipment/pro/#{shipment.load_id}/verified", headers:)
      end

      it { expect(response.headers['Last-Modified']).to(eq(customer.updated_at.httpdate)) }
    end

    context 'when the request repeats the Last-Modified date' do
      before do
        get("/api/dsdc/shipment/pro/#{shipment.load_id}/verified", headers:)
        get("/api/dsdc/shipment/pro/#{shipment.load_id}/verified",
            headers: headers.merge('If-Modified-Since' => response.headers['Last-Modified']))
      end

      it { expect(response).to(have_http_status(:not_modified)) }
    end

    context 'when the request repeats the ETag' do
      before do
        get("/api/dsdc/shipment/pro/#{shipment.load_id}/verified", headers:)
        get("/api/dsdc/shipment/pro/#{shipment.load_id}/verified", headers: headers.merge('If-None-Match' => response.headers['ETag']))
      end

      it { expect(response).to(have_http_status(:not_modified)) }
    end

    context 'when the shipment becomes late after the response' do
      let(:path) { "/api/dsdc/shipment/pro/#{shipment.load_id}/verified" }
      let!(:shipment) do
        create(
          :shipment,
          broker_customer: api_key.user.companyable,
          delivered_at: nil,
          delivery_appointment_at: nil,
          delivery_appointment_on: nil,
          delivery_eta_on: Date.current,
          picked_up_at: 1.day.ago,
          promised_delivery_by: nil
        )
      end

      before do
        get(path, headers:)
        conditional_headers = { 'If-Modified-Since' => response.headers['Last-Modified'], 'If-None-Match' => response.headers['ETag'] }

        Timecop.travel(2.days.from_now)
        get(path, headers: headers.merge(conditional_headers))
      end

      after { Timecop.return }

      it { expect(response).to(have_http_status(:ok)) }
      it { expect(json['Late']).to(be(true)) }
      it { expect(response.headers['Last-Modified']).to(eq(shipment.late_since.httpdate)) }
    end

    context 'when the shipment becomes late and the request repeats only the Last-Modified date' do
      let(:path) { "/api/dsdc/shipment/pro/#{shipment.load_id}/verified" }
      let!(:shipment) do
        create(
          :shipment,
          broker_customer: api_key.user.companyable,
          delivered_at: nil,
          delivery_appointment_at: nil,
          delivery_appointment_on: nil,
          delivery_eta_on: Date.current,
          picked_up_at: 1.day.ago,
          promised_delivery_by: nil
        )
      end

      before do
        get(path, headers:)
        last_modified = response.headers['Last-Modified']

        Timecop.travel(2.days.from_now)
        get(path, headers: headers.merge('If-Modified-Since' => last_modified))
      end

      after { Timecop.return }

      it { expect(response).to(have_http_status(:ok)) }
    end

    context 'when the shipment belongs to another customer' do
      let!(:shipment) { create(:shipment) }

      before { get("/api/dsdc/shipment/pro/#{shipment.load_id}/verified", headers:) }

      it { expect(response).to(have_http_status(:not_found)) }
    end

    context 'when the shipment is missing' do
      before { get('/api/dsdc/shipment/pro/0/verified', headers:) }

      it { expect(response).to(have_http_status(:not_found)) }
    end

    context 'when the API key is missing' do
      before { get("/api/dsdc/shipment/pro/#{shipment.load_id}/verified") }

      it { expect(response).to(have_http_status(:unauthorized)) }
      it { expect(json['message']).to(eq(I18n.t('api_keys.errors.missing'))) }
    end
  end

  describe 'GET /api/dsdc/shipment/bol/:bol/:origin_postal_code/verified' do
    before { get("/api/dsdc/shipment/bol/1001/#{postal_code}/verified", headers:) }

    context 'with the origin postal code' do
      let(:postal_code) { shipment.shipper_address.zip_code }

      it { expect(json['ProNumber']).to(eq(shipment.load_id.to_s)) }
    end

    context 'with the origin ZIP+4 code' do
      let(:postal_code) { "#{shipment.shipper_address.zip_code}-1234" }

      it { expect(json['ProNumber']).to(eq(shipment.load_id.to_s)) }
    end

    context 'with another postal code' do
      let(:postal_code) { '00000' }

      it { expect(response).to(have_http_status(:not_found)) }
    end

    context 'with a partial postal code' do
      let(:postal_code) { shipment.shipper_address.zip_code.first(3) }

      it { expect(response).to(have_http_status(:not_found)) }
    end

    context 'when another customer has a shipment with the same BOL and origin' do
      let(:other_shipment) do
        create(:shipment, bol: '1001').tap { |other| other.shipper_address.update!(zip_code: shipment.shipper_address.zip_code) }
      end
      let(:postal_code) { other_shipment.shipper_address.zip_code }

      it { expect(json['ProNumber']).to(eq(shipment.load_id.to_s)) }
    end
  end

  describe 'GET /api/dsdc/shipment/po/:po/:destination_postal_code/verified' do
    before { get("/api/dsdc/shipment/po/2002/#{shipment.receiver_address.zip_code}/verified", headers:) }

    it { expect(json['ProNumber']).to(eq(shipment.load_id.to_s)) }
  end

  describe 'GET /api/dsdc/shipment/po/:account_number/:start_date/:end_date/verified' do
    before { get("/api/dsdc/shipment/po/#{shipment.broker_customer_id}/#{start_date}/#{start_date.next_day}/verified", headers:) }

    context 'when a shipment picks up in the range' do
      let(:start_date) { shipment.pickup_on }

      it { expect(json.pluck('ProNumber')).to(eq([shipment.load_id.to_s])) }
    end

    context 'when the request repeats the ETag' do
      let(:queries) { [] }
      let(:start_date) { shipment.pickup_on }

      before do
        path = "/api/dsdc/shipment/po/#{shipment.broker_customer_id}/#{start_date}/#{start_date.next_day}/verified"
        conditional_headers = headers.merge('If-None-Match' => response.headers['ETag'])
        subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') { |*, payload| queries << payload[:sql] }
        get(path, headers: conditional_headers)
        ActiveSupport::Notifications.unsubscribe(subscriber)
      end

      it { expect(response).to(have_http_status(:not_modified)) }
      it { expect(queries.grep(/SELECT "(broker_accessorials|items|packagings|tracking_events)"\.\*/)).to(be_empty) }
    end

    context 'when an item changed after the shipment' do
      let!(:shipment) { super().tap { |shipment| create(:item, shipment:, updated_at: 1.day.from_now) } }
      let(:start_date) { shipment.pickup_on }

      it { expect(response.headers['Last-Modified']).to(eq(shipment.items.sole.updated_at.httpdate)) }
    end

    context 'when a shipment becomes late after the response' do
      let!(:shipment) do
        create(
          :shipment,
          broker_customer: api_key.user.companyable,
          delivered_at: nil,
          delivery_appointment_at: nil,
          delivery_appointment_on: nil,
          delivery_eta_on: Date.current,
          picked_up_at: 1.day.ago,
          promised_delivery_by: nil
        )
      end
      let(:start_date) { shipment.pickup_on }

      before do
        last_modified = response.headers['Last-Modified']

        Timecop.travel(2.days.from_now)
        get(
          "/api/dsdc/shipment/po/#{shipment.broker_customer_id}/#{start_date}/#{start_date.next_day}/verified",
          headers: headers.merge('If-Modified-Since' => last_modified)
        )
      end

      after { Timecop.return }

      it { expect(response).to(have_http_status(:ok)) }
      it { expect(json.sole['Late']).to(be(true)) }
    end

    context 'with a broker carrier API key' do
      let(:api_key) { create(:api_key, :carrier) }
      let!(:shipment) { create(:shipment, broker_carrier: create(:broker_carrier, carrier: api_key.user.companyable)) }
      let(:start_date) { shipment.pickup_on }

      it { expect(response).to(have_http_status(:not_found)) }
    end

    context 'when no shipment picks up in the range' do
      let(:start_date) { shipment.pickup_on.next_year }

      it { expect(response).to(have_http_status(:no_content)) }
    end
  end

  describe 'GET /api/dsdc/shipment/pro/:pro/public' do
    before { get("/api/dsdc/shipment/pro/#{shipment.load_id}/public") }

    it { expect(json.keys).to(eq(['EstimatedStandardDay', 'ProNumber', 'ShipmentMilestoneStatus', 'UpdatedETA'])) }
  end
end
