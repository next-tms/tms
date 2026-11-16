require 'rails_helper'

RSpec.describe('BrokerWare invoices') do
  let(:api_key) { create(:api_key, user:) }
  let(:broker_customer) { create(:broker_customer, requires_carrier_bol_on_receivables: false, requires_carrier_pod_on_receivables: false) }
  let(:headers) { { 'Authorization' => "Bearer #{api_key.access_token}" } }
  let(:json) { JSON.parse(response.body, symbolize_names: true) }
  let(:path) { '/api/v1/invoice' }
  let(:query) { {} }
  let(:receivable) { create(:receivable, receivable_items:, shipment: create(:shipment, :usd, broker_customer:)) }
  let(:receivable_items) do
    [
      ReceivableItem.new(charge_cents: 37_500, charge_currency: 'USD', description: 'Linehaul'),
      ReceivableItem.new(charge_cents: 3_770, charge_currency: 'USD', description: 'Fuel Surcharge')
    ]
  end
  let(:user) { create(:customer_user, companyable: broker_customer).tap { |customer_user| customer_user.add_role(:accounts_payable) } }

  before do
    seed_settings
    receivable
    create(:receivable)
    get(path, headers:, params: query)
  end

  describe 'GET /api/v1/invoice' do
    it { is_expected.to(have_http_status(:ok)) }
    it { expect(json.pluck(:loadId)).to(eq([receivable.shipment.load_id])) }
    it { expect(json.sole).to(include(invoiceNumber: receivable.shipment.load_id.to_s, term: nil, totalBilled: 412.7)) }
    it { expect(json.sole[:accessorials]).to(include({ billed: 37.7, description: 'Fuel Surcharge' })) }
    it { expect(json.sole[:accessorials]).to(include({ billed: 375.0, description: 'Linehaul' })) }
    it { expect(json.sole.keys).to(include(:billToCompany, :remitToCompany)) }
    it { expect(response.body).not_to(include('"cost"')) }

    context 'without the accounts payable role' do
      let(:user) { create(:customer_user, companyable: broker_customer) }

      it { is_expected.to(have_http_status(:not_found)) }
    end
  end

  describe 'GET /api/v1/Invoice/customfields' do
    let(:path) { '/api/v1/Invoice/customfields' }

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(json.sole[:customFields]).to(eq([])) }
    it { expect(json.sole.keys).not_to(include(:billToCompany, :remitToCompany)) }

    context 'with a date range before the invoice' do
      let(:query) { { endDate: 1.month.ago.to_date.iso8601, startDate: 2.months.ago.to_date.iso8601 } }

      it { expect(json).to(be_empty) }
    end

    context 'with an invalid date' do
      let(:query) { { startDate: 'last month' } }

      it { is_expected.to(have_http_status(:bad_request)) }
    end
  end
end
