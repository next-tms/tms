require 'rails_helper'

RSpec.describe('DSDC::Documents') do
  let(:api_key) { create(:api_key, :broker_carrier, authorizable: broker_carrier) }
  let(:body) do
    {
      DOT: '1234567',
      MC: '654321',
      documents:,
      invoiceDate: '2026-11-01',
      invoiceNumber: 'CARRIER-INV-100',
      shipmentID: shipment.load_id.to_s,
      uniqueID: 'INV-UNIQUE-1'
    }
  end
  let(:broker_carrier) { create(:broker_carrier, carrier: create(:carrier, mc_number: 654_321)) }
  let(:document_types) { payment_transaction.reload.dsdc_documents.map { |document| document.metadata['document_type'] } }
  let(:documents) { [{ documentType: 'POD', files: [pdf] }, { documentType: 'IMG', files: [png] }] }
  let(:headers) { { 'Content-Type' => 'application/json', 'X-API-Key' => api_key.token } }
  let(:json) { response.parsed_body }
  let(:pdf) { Base64.strict_encode64("%PDF-1.4\n1 0 obj << /Type /Catalog >> endobj\ntrailer << /Root 1 0 R >>\n%%EOF\n") }
  let(:png) { 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==' }
  let(:shipment) { create(:shipment, :usd, broker_carrier:) }

  let!(:payment_transaction) do
    create(
      :payment_transaction,
      broker_carrier:,
      dsdc_invoice: { 'DOT' => '1234567', 'MC' => '654321', 'invoiceHeader' => { 'invoiceDate' => '2026-11-01' }, 'shipmentID' => 'S1' },
      dsdc_unique_id: 'INV-UNIQUE-1',
      invoice: 'CARRIER-INV-100',
      shipment:
    )
  end

  describe 'DELETE /api/dsdc/v1/documents/:invoice_number' do
    let(:query) { '' }

    before do
      post('/api/dsdc/v1/documents', headers:, params: body.to_json)
      delete("/api/dsdc/v1/documents/CARRIER-INV-100#{query}", headers:)
    end

    it { is_expected.to(have_http_status(:no_content)) }
    it { expect(payment_transaction.reload.dsdc_documents).not_to(be_attached) }

    context 'with file IDs' do
      let(:query) do
        image = payment_transaction.dsdc_documents_attachments.find { |attachment| attachment.blob.metadata['document_type'] == 'IMG' }

        "?fileIds[]=#{image.id}"
      end

      it { expect(document_types).to(eq(['POD'])) }
    end
  end

  describe 'GET /api/dsdc/v1/documents' do
    let(:max_response_size) { DSDC::DocumentsController::MAX_RESPONSE_SIZE }

    before do
      stub_const('DSDC::DocumentsController::MAX_RESPONSE_SIZE', max_response_size)
      post('/api/dsdc/v1/documents', headers:, params: body.to_json)
      get('/api/dsdc/v1/documents', headers:, params:)
    end

    context 'when the documents exceed the response size' do
      let(:max_response_size) { 1 }
      let(:params) { {} }

      it { is_expected.to(have_http_status(:bad_request)) }
      it { expect(json).to(eq(['500'])) }
    end

    context 'with a document type' do
      let(:params) { { documentType: ['POD'] } }

      it { expect(json.sole['documents'].pluck('documentType')).to(eq(['POD'])) }
    end

    context 'with a document type that matches no file' do
      let(:params) { { documentType: ['BOL'] } }

      it { expect(json).to(be_empty) }
    end

    context 'without filters' do
      let(:params) { {} }

      it { is_expected.to(have_http_status(:ok)) }
      it { expect(json.sole).to(include('DOT' => '1234567', 'invoiceNumber' => 'CARRIER-INV-100', 'uniqueID' => 'INV-UNIQUE-1')) }
      it { expect(json.sole['documents'].pluck('documentType')).to(contain_exactly('IMG', 'POD')) }
      it { expect(json.sole['documents'].find { |document| document['documentType'] == 'IMG' }['files'].sole['content']).to(eq(png)) }
    end
  end

  describe 'GET /api/dsdc/v1/documents/:invoice_number' do
    let(:max_response_size) { DSDC::DocumentsController::MAX_RESPONSE_SIZE }

    before do
      stub_const('DSDC::DocumentsController::MAX_RESPONSE_SIZE', max_response_size)
      post('/api/dsdc/v1/documents', headers:, params: body.to_json)
      get('/api/dsdc/v1/documents/CARRIER-INV-100', headers:)
    end

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(json).to(include('invoiceDate' => '2026-11-01', 'shipmentID' => 'S1')) }
    it { expect(json['documents'].pluck('documentType')).to(contain_exactly('IMG', 'POD')) }

    context 'when the documents exceed the response size' do
      let(:max_response_size) { 1 }

      it { is_expected.to(have_http_status(:bad_request)) }
      it { expect(json).to(eq(['500'])) }
    end
  end

  describe 'POST /api/dsdc/v1/documents' do
    before { post('/api/dsdc/v1/documents', headers:, params: body.to_json) }

    it { is_expected.to(have_http_status(:created)) }
    it { expect(json).to(eq('message' => I18n.t('dsdc.documents.create.message'))) }
    it { expect(payment_transaction.dsdc_documents.map(&:content_type)).to(contain_exactly('application/pdf', 'image/png')) }
    it { expect(document_types).to(contain_exactly('IMG', 'POD')) }
    it { expect(payment_transaction.dsdc_documents.blobs).to(include(shipment.reload.carrier_pod.blob)) }

    context 'when the shipment already has a POD' do
      let(:shipment) do
        create(:shipment, :usd, broker_carrier:).tap do |shipment|
          shipment.carrier_pod.attach(io: StringIO.new('existing'), filename: 'existing.pdf')
        end
      end

      it { expect(shipment.reload.carrier_pod.filename.to_s).to(eq('existing.pdf')) }
    end

    context 'with a file type that is not allowed' do
      let(:documents) { [{ documentType: 'POD', files: [Base64.strict_encode64('plain text')] }] }

      it { is_expected.to(have_http_status(:bad_request)) }
      it { expect(json).to(eq(['400'])) }
    end

    context 'with an invoice that does not exist' do
      let(:body) { super().merge(uniqueID: 'UNKNOWN') }

      it { is_expected.to(have_http_status(:not_found)) }
      it { expect(json).to(eq(['300'])) }
    end

    context 'with an unknown document type' do
      let(:documents) { [{ documentType: 'NOPE', files: [pdf] }] }

      it { is_expected.to(have_http_status(:bad_request)) }
      it { expect(json).to(eq(['400'])) }
      it { expect(payment_transaction.dsdc_documents).not_to(be_attached) }
    end
  end
end
