require 'rails_helper'

RSpec.describe('DSDC::Invoices') do
  let(:api_key) { create(:api_key, user: create(:carrier_user, companyable: broker_carrier.carrier)) }
  let(:body) { JSON.parse(file_fixture('dsdc/invoice_request.json').read.sub('SHIPMENT_ID', shipment.load_id.to_s)) }
  let(:broker_carrier) { create(:broker_carrier, carrier: create(:carrier, mc_number: 654_321)) }
  let(:existing_payment_transaction) do
    create(:payment_transaction, broker_carrier:, dsdc_invoice: body, dsdc_unique_id: 'INV-UNIQUE-1', shipment:)
  end
  let(:headers) { { 'Content-Type' => 'application/json', 'X-API-Key' => api_key.token } }
  let(:json) { response.parsed_body }
  let(:payment_transaction) { PaymentTransaction.find_by(dsdc_unique_id: 'INV-UNIQUE-1') }
  let(:shipment) { create(:shipment, :usd, broker_carrier:, carrier_cost_cents: 50_000, pro: 'A7770123') }

  describe 'POST /api/dsdc/v1/invoices' do
    before { post('/api/dsdc/v1/invoices', headers:, params: body.to_json) }

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(json).to(eq('message' => I18n.t('dsdc.invoices.create.message'))) }

    it do
      expect(payment_transaction).to(
        have_attributes(
          balance: Money.from_amount(425.50, 'USD'),
          broker_carrier:,
          due_on: Date.new(2026, 12, 1),
          invoice: 'CARRIER-INV-100',
          notes: 'Delivered on time.',
          pro: 'A7770123',
          shipment:
        )
      )
    end

    it { expect(payment_transaction.dsdc_invoice).to(eq(body)) }

    context 'with the shipment PRO as the shipment ID' do
      let(:body) { JSON.parse(file_fixture('dsdc/invoice_request.json').read.sub('SHIPMENT_ID', shipment.pro)) }

      it { expect(payment_transaction.shipment).to(eq(shipment)) }
    end

    context 'when another shipment has a PRO equal to the load ID' do
      let(:body) do
        create(:shipment, :usd, broker_carrier:, pro: shipment.load_id.to_s)

        JSON.parse(file_fixture('dsdc/invoice_request.json').read.sub('SHIPMENT_ID', shipment.load_id.to_s))
      end

      it { expect(payment_transaction.shipment).to(eq(shipment)) }
    end

    context 'with a shipment that belongs to another carrier' do
      let(:shipment) { create(:shipment, :usd, broker_carrier: create(:broker_carrier)) }

      it { is_expected.to(have_http_status(:not_found)) }
      it { expect(json).to(eq(['300'])) }
    end

    context 'with an MC number that does not match the carrier' do
      let(:body) { super().merge('MC' => '111111') }

      it { is_expected.to(have_http_status(:bad_request)) }
      it { expect(json).to(eq(['300'])) }
    end

    context 'with a PRO shared by shipments on two accounts of the carrier' do
      let(:body) do
        create(:shipment, :usd, broker_carrier: other_account, pro: shipment.pro)

        JSON.parse(file_fixture('dsdc/invoice_request.json').read.sub('SHIPMENT_ID', shipment.pro))
      end
      let(:other_account) { create(:broker_carrier, broker_customer: create(:broker_customer), carrier: broker_carrier.carrier) }

      it { is_expected.to(have_http_status(:not_found)) }
      it { expect(json).to(eq(['300'])) }
    end

    context 'with a shipment on another account of the carrier' do
      let(:other_account) { create(:broker_carrier, broker_customer: create(:broker_customer), carrier: broker_carrier.carrier) }
      let(:shipment) { create(:shipment, :usd, broker_carrier: other_account, carrier_cost_cents: 50_000, pro: 'A7770123') }

      it { is_expected.to(have_http_status(:ok)) }
      it { expect(payment_transaction.broker_carrier).to(eq(other_account)) }
    end

    context 'when the unique ID was already sent on another account of the carrier' do
      let(:body) do
        create(:payment_transaction, broker_carrier: other_account, dsdc_unique_id: 'INV-UNIQUE-1', shipment: create(:shipment, :usd))

        super()
      end
      let(:other_account) { create(:broker_carrier, broker_customer: create(:broker_customer), carrier: broker_carrier.carrier) }

      it { is_expected.to(have_http_status(:bad_request)) }
      it { expect(PaymentTransaction.where(dsdc_unique_id: 'INV-UNIQUE-1').count).to(eq(1)) }
    end

    context 'when the unique ID was already sent' do
      before { post('/api/dsdc/v1/invoices', headers:, params: body.to_json) }

      it { is_expected.to(have_http_status(:bad_request)) }
      it { expect(json).to(eq(['300'])) }
      it { expect(PaymentTransaction.where(dsdc_unique_id: 'INV-UNIQUE-1').count).to(eq(1)) }
    end

    context 'without an invoice header' do
      let(:body) { { uniqueID: 'X', shipmentID: shipment.load_id.to_s, DOT: '1', MC: '654321', invoiceCharges: [] } }

      it { is_expected.to(have_http_status(:bad_request)) }
      it { expect(json).to(eq(['400'])) }
    end

    context 'with a user API key' do
      let(:api_key) { create(:api_key) }

      it { is_expected.to(have_http_status(:not_found)) }
      it { expect(json).to(eq(['300'])) }
    end
  end

  describe 'GET /api/dsdc/v1/invoices' do
    let(:other_carrier_api_key) { create(:api_key, :carrier) }

    before do
      post('/api/dsdc/v1/invoices', headers:, params: body.to_json)
      get('/api/dsdc/v1/invoices', headers:, params:)
    end

    context 'without filters' do
      let(:params) { {} }

      it { is_expected.to(have_http_status(:ok)) }
      it { expect(json).to(eq([body])) }
    end

    context 'with a matching invoice number' do
      let(:params) { { invoiceNumber: 'CARRIER-INV-100' } }

      it { expect(json).to(eq([body])) }
    end

    context 'with a DOT number that matches no invoice' do
      let(:params) { { DOT: '999' } }

      it { expect(json).to(be_empty) }
    end

    context 'with another carrier API key' do
      let(:params) { {} }

      before { get('/api/dsdc/v1/invoices', headers: headers.merge('X-API-Key' => other_carrier_api_key.token)) }

      it { expect(json).to(be_empty) }
    end
  end

  describe 'GET /api/dsdc/v1/invoices/:unique_id' do
    let(:unique_id) { existing_payment_transaction.dsdc_unique_id }

    before { get("/api/dsdc/v1/invoices/#{unique_id}", headers:) }

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(json).to(eq(body)) }

    context 'with an unknown unique ID' do
      let(:unique_id) { 'UNKNOWN' }

      it { is_expected.to(have_http_status(:not_found)) }
    end

    context 'when two accounts of the carrier share the unique ID' do
      let(:other_account) { create(:broker_carrier, broker_customer: create(:broker_customer), carrier: broker_carrier.carrier) }
      let(:duplicate) { build(:payment_transaction, duplicate_attributes) }
      let(:duplicate_attributes) { { broker_carrier: other_account, dsdc_invoice: {}, dsdc_unique_id: 'INV-UNIQUE-1', shipment: } }
      let(:unique_id) do
        existing_payment_transaction
        duplicate.save!(validate: false)

        existing_payment_transaction.dsdc_unique_id
      end

      it { is_expected.to(have_http_status(:not_found)) }
    end
  end

  describe 'PUT /api/dsdc/v1/invoices/:unique_id' do
    let(:unique_id) { existing_payment_transaction.dsdc_unique_id }

    before do
      body['invoiceHeader']['invoiceAmount']['value'] = '450.00'
      put("/api/dsdc/v1/invoices/#{unique_id}", headers:, params: body.to_json)
    end

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(existing_payment_transaction.reload.balance).to(eq(Money.from_amount(450, 'USD'))) }

    context 'with an unknown unique ID' do
      let(:unique_id) { 'UNKNOWN' }

      it { is_expected.to(have_http_status(:not_found)) }
    end

    context 'when the path and body unique IDs differ' do
      let(:unique_id) { create(:payment_transaction, broker_carrier:, dsdc_invoice: {}, dsdc_unique_id: 'OTHER', shipment:).dsdc_unique_id }

      it { is_expected.to(have_http_status(:bad_request)) }
      it { expect(json).to(eq(['400'])) }
    end

    context 'when the bill is part of a payment' do
      let(:payment) { Payment.create!(broker_carrier:, due_on: Date.current) }
      let(:existing_payment_transaction) do
        create(:payment_transaction, broker_carrier:, dsdc_invoice: body, dsdc_unique_id: 'INV-UNIQUE-1', payment:, shipment:)
      end

      it { is_expected.to(have_http_status(:bad_request)) }
      it { expect(json).to(eq(['500'])) }
    end
  end

  describe 'DELETE /api/dsdc/v1/invoices/:unique_id' do
    before do
      post('/api/dsdc/v1/invoices', headers:, params: body.to_json)
      delete('/api/dsdc/v1/invoices/INV-UNIQUE-1', headers:)
    end

    it { is_expected.to(have_http_status(:no_content)) }
    it { expect(payment_transaction).to(be_nil) }
  end
end
