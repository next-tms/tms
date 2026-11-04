require 'rails_helper'

RSpec.describe('Broker::Carriers::Contacts') do
  let(:broker_carrier) { create(:broker_carrier, carrier:) }
  let(:carrier) { create(:carrier, name: 'Acme Freight') }
  let(:current_user) { create(:root_broker_user) }
  let(:other_broker_carrier) { create(:broker_carrier, broker_customer: create(:broker_customer), carrier:) }

  before do
    seed_settings
    sign_in(current_user)
  end

  describe 'GET /broker/carriers/:carrier_id/contacts' do
    let!(:contact) { create(:contact, companyable: carrier, first_name: 'Dana') }

    before { get("/broker/carriers/#{broker_carrier.carrier_id}/contacts") }

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(assigns(:contacts)).to(contain_exactly(contact)) }
  end
end
