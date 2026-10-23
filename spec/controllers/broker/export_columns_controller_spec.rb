require 'rails_helper'

RSpec.describe(Broker::ExportColumnsController) do
  subject { response }

  render_views

  let(:association) { 'broker_customer' }
  let(:params) { { association:, name: 'columns[]', record_type: 'Shipment' } }
  let(:user) { create(:root_broker_user) }

  before do
    sign_in(user)
    get(:show, params:)
  end

  it { is_expected.to(have_http_status(:ok)) }
  it { expect(response.body).to(include('<turbo-frame id="export-columns-shipment-broker_customer">')) }
  it { expect(response.body).to(include('name="columns[]"', 'value="broker_customer.name"', 'id="shipment_columns_broker_customer_name"')) }
  it { expect(response.body).to(include('export-columns-shipment-broker_customer-office_address')) }
  it { expect(response.body).not_to(include('checked')) }
  it { expect(response.body).not_to(include('badge')) }

  context 'when fresh' do
    before do
      request.headers['If-None-Match'] = response.etag
      get(:show, params:)
    end

    it { is_expected.to(have_http_status(:not_modified)) }
  end

  context 'with internal columns marked' do
    let(:association) { 'broker_carrier' }
    let(:params) { super().merge(mark_internal: 'true', name: 'report[columns][]') }

    it { expect(response.body).to(include('name="report[columns][]"', 'badge text-bg-warning')) }
  end

  context 'with an unknown input name' do
    let(:params) { super().merge(name: 'user[admin]') }

    it { expect(response.body).to(include('name="columns[]"')) }
    it { expect(response.body).not_to(include('user[admin]')) }
  end

  context 'with an association the user cannot export' do
    let(:association) { 'broker' }

    it { is_expected.to(have_http_status(:not_found)) }
  end

  context 'with an unknown record type' do
    let(:params) { super().merge(record_type: 'User') }

    it { is_expected.to(have_http_status(:not_found)) }
  end

  context 'with a record type the user cannot list' do
    let(:association) { 'shipment' }
    let(:params) { super().merge(record_type: 'Receivable') }
    let(:user) { create(:broker_user) }

    it { is_expected.to(have_http_status(:not_found)) }

    context 'when the user is in accounts receivable' do
      let(:user) { create(:broker_user).tap { |user| create(:contact_role, contact: user.contact, role: :accounts_receivable) } }

      it { is_expected.to(have_http_status(:ok)) }
    end
  end

  context 'when a customer user' do
    let(:user) { create(:customer_user) }

    it { is_expected.not_to(have_http_status(:ok)) }
  end
end
