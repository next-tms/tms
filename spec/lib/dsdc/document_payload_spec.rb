require 'rails_helper'

RSpec.describe(DSDC::DocumentPayload) do
  subject(:payload) { described_class.new(body) }

  let(:body) do
    {
      'DOT' => '1234567',
      'MC' => '654321',
      'documents' => documents,
      'invoiceDate' => '2026-11-01',
      'invoiceNumber' => 'INV-100',
      'shipmentID' => '42',
      'uniqueID' => 'UNIQUE-1'
    }
  end
  let(:documents) { [{ 'documentType' => 'POD', 'files' => [pdf] }] }
  let(:pdf) { Base64.strict_encode64("%PDF-1.4\n%%EOF\n") }

  describe '#attachables' do
    let(:attachable) { payload.attachables.sole }

    it { expect(attachable).to(include(content_type: 'application/pdf', filename: 'INV-100-pod-1.pdf')) }
    it { expect(attachable[:metadata]).to(eq(document_type: 'POD')) }

    context 'with an unknown document type' do
      let(:documents) { [{ 'documentType' => 'NOPE', 'files' => [pdf] }] }

      it { expect { payload.attachables }.to(raise_error(ArgumentError)) }
    end

    context 'with a file type that is not allowed' do
      let(:documents) { [{ 'documentType' => 'POD', 'files' => [Base64.strict_encode64('plain text')] }] }

      it { expect { payload.attachables }.to(raise_error(ArgumentError)) }
    end

    context 'with a file that is not Base64' do
      let(:documents) { [{ 'documentType' => 'POD', 'files' => ['not base64!'] }] }

      it { expect { payload.attachables }.to(raise_error(ArgumentError)) }
    end
  end

  describe '#invoice_number' do
    it { expect(payload.invoice_number).to(eq('INV-100')) }
  end

  describe '#unique_id' do
    it { expect(payload.unique_id).to(eq('UNIQUE-1')) }
  end
end
