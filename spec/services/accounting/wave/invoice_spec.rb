require 'rails_helper'

RSpec.describe Accounting::Wave::Invoice do
  let!(:integration) { create(:integration, :wave, credentials: { access_token: 'access', business_id: 'biz', product_id: 'prod-1' }) }

  describe '.create' do
    subject(:created) do
      described_class.create(
        customer_id: 'cust-1',
        document_number: '1001',
        due_date: Date.new(2026, 8, 15),
        line_items: [Accounting::LineItem.new(kind: :sales, description: 'Freight', quantity: 1, unit_price: 1234.56)],
        transaction_date: Time.utc(2026, 7, 30)
      )
    end

    before { stub_wave('invoice_create') }

    it { is_expected.to have_attributes(id: 'inv-1', document_number: '1001', email_status: 'EmailSent') }
    it { expect(created.total).to eq(Money.new(123_456)) }

    context 'when sending the mutation' do
      before { created }

      it do
        expect(WebMock)
          .to(
            have_requested(:post, Accounting::Wave::Service::GRAPHQL_URL)
            .with do |request|
              body = JSON.parse(request.body)
              item = body.dig('variables', 'input', 'items').first
              body['query'].include?('invoiceCreate') && item.values_at('productId', 'unitPrice') == ['prod-1', 1234.56]
            end
          )
      end
    end
  end

  describe '.find' do
    subject(:found) { described_class.find('inv-1') }

    before { stub_wave('invoice') }

    it { is_expected.to have_attributes(id: 'inv-1', customer_id: 'cust-1', document_number: '1001') }
    it { expect(found.balance).to eq(Money.new(123_456)) }
  end

  describe '.find_by' do
    subject(:found) { described_class.find_by(document_number: '1001') }

    before { stub_wave('invoice_find_by') }

    it { is_expected.to have_attributes(id: 'inv-1') }

    context 'when sending the query' do
      before { found }

      it { expect(WebMock).to(have_requested(:post, Accounting::Wave::Service::GRAPHQL_URL).with { |request| JSON.parse(request.body).dig('variables', 'invoiceNumber') == '1001' }) }
    end
  end

  describe '#pdf' do
    subject(:pdf) { described_class.new('inv-1').pdf }

    before do
      stub_wave('invoice_pdf')
      stub_request(:get, 'https://accounting.waveapps.example/inv-1.pdf').to_return(status: 200, body: '%PDF-data')
    end

    it { is_expected.to eq('%PDF-data') }
  end
end
