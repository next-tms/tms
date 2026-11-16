require 'rails_helper'

RSpec.describe('BrokerWare documents') do
  let(:api_key) { create(:api_key, user: create(:customer_user, companyable: broker_customer)) }
  let(:broker_customer) { create(:broker_customer) }
  let(:headers) { { 'Authorization' => "Bearer #{api_key.access_token}" } }
  let(:json) { JSON.parse(response.body, symbolize_names: true) }
  let(:shipment) { create(:shipment, broker_customer:) }

  before do
    allow(DocumentableService).to(receive(:call))

    ['broker_bol', 'broker_dispatch_sheet', 'broker_quote'].each do |name|
      blob = ActiveStorage::Blob.create_and_upload!(content_type: 'application/pdf', filename: "#{name}.pdf", io: StringIO.new('%PDF-1.4'))
      ActiveStorage::Attachment.create!(blob:, name:, record: shipment)
    end
  end

  describe 'GET /api/v1/ListShipmentDocuments' do
    before { get('/api/v1/ListShipmentDocuments', headers:, params: { loadId: shipment.load_id }) }

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(json).to(contain_exactly('BOL', 'Quote')) }

    context 'when the shipment belongs to another customer' do
      let(:shipment) { create(:shipment) }

      it { is_expected.to(have_http_status(:not_found)) }
    end
  end

  describe 'GET /api/v1/LoadDocsbyURL' do
    before { get('/api/v1/LoadDocsbyURL', headers:, params: { loadId: shipment.load_id }) }

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(json.pluck(:name, :documentListType)).to(contain_exactly(['BOL', 1], ['Quote', 0])) }
    it { expect(json.pluck(:url)).to(all(include('/rails/active_storage/'))) }
  end

  describe 'POST /api/v1/SendShipmentDocuments' do
    let(:params) { { documentNames: ['BOL', 'Quote'], emails: ['receiving@example.com'], loadId: shipment.load_id.to_s } }

    before do
      seed_settings
      create(:setting, key: 'robot_email', value: 'robot@example.com')
      ActionMailer::Base.deliveries.clear
      post('/api/v1/SendShipmentDocuments', as: :json, headers:, params:)
    end

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(ActionMailer::Base.deliveries.size).to(eq(2)) }
    it { expect(ActionMailer::Base.deliveries.flat_map(&:to).uniq).to(eq(['receiving@example.com'])) }

    context 'with a document the customer cannot see' do
      let(:params) { super().merge(documentNames: ['Dispatch Sheet']) }

      it { is_expected.to(have_http_status(:bad_request)) }
      it { expect(ActionMailer::Base.deliveries).to(be_empty) }
    end

    context 'with an invalid email' do
      let(:params) { super().merge(emails: ['not an email']) }

      it { is_expected.to(have_http_status(:bad_request)) }
    end

    context 'with too many emails' do
      let(:params) { super().merge(emails: Array.new(11) { |index| "user#{index}@example.com" }) }

      it { is_expected.to(have_http_status(:bad_request)) }
    end
  end
end
