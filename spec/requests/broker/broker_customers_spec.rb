require 'rails_helper'

RSpec.describe('Broker::BrokerCustomers') do
  subject { response }

  let(:broker_customer) { create(:broker_customer, customer:) }
  let(:current_user) { create(:root_broker_user) }
  let(:customer) { create(:customer, legal_name: 'ACME HOLDINGS, LLC DBA ACME FREIGHT', name: 'Acme Freight') }

  before do
    seed_settings
    create(:setting, key: 'mailing_address', value: create(:address))
    sign_in(current_user)
  end

  describe 'GET /broker/customers/:id/contacts' do
    before do
      create(:contact, companyable: broker_customer, first_name: 'Zed')
      create(:contact, companyable: broker_customer, first_name: 'Abe')
      get("/broker/customers/#{broker_customer.id}/contacts")
    end

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(response.body).to(match(/Abe.*Zed/m)) }
  end

  describe 'GET /broker/customers/:id/edit' do
    before { get("/broker/customers/#{broker_customer.id}/edit") }

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(response.body).to(match(/\[legal_name\].*\[customer_attributes\]\[name\]/m)) }
    it { expect(response.body).to(include('data-controller="legal-name"')) }
  end

  describe 'GET /broker/customers/:id/pricing/edit' do
    let(:select) { Nokogiri::HTML(response.body).at_css('template select[name$="[transponder_code]"]') }

    before { get("/broker/customers/#{broker_customer.id}/pricing/edit") }

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(select.css('option').pluck('value')).to(include('liftgate_delivery')) }
  end

  describe 'GET /broker/customers/new' do
    before { get('/broker/customers/new') }

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(response.body).to(match(/\[legal_name\].*\[customer_attributes\]\[name\]/m)) }
  end

  describe 'PATCH /broker/customers/:id' do
    before do
      patch(
        "/broker/customers/#{broker_customer.id}",
        params: { broker_customer: { customer_attributes: { id: customer.id, legal_name: 'Acme Freight, Inc.', name: 'Acme' } } }
      )
    end

    it { is_expected.to(redirect_to("/broker/customers/#{broker_customer.id}")) }
    it { expect(customer.reload).to(have_attributes(legal_name: 'Acme Freight, Inc.', name: 'Acme')) }
  end

  describe 'PATCH /broker/customers/:id/pricing/update' do
    let(:accessorials_attributes) { [{ code: 'CLIF', name: 'Customer liftgate', transponder_code: 'liftgate_delivery' }] }

    before { patch("/broker/customers/#{broker_customer.id}/pricing/update", params: { broker_customer: { accessorials_attributes: } }) }

    it { is_expected.to(redirect_to("/broker/customers/#{broker_customer.id}/pricing/edit")) }

    it { expect(broker_customer.accessorials.sole).to(have_attributes(code: 'CLIF', transponder_code: 'liftgate_delivery')) }
    it { expect(broker_customer.accessorials.sole.name).to(eq('Customer liftgate')) }
  end
end
