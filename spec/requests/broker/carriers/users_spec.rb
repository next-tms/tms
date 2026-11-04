require 'rails_helper'

RSpec.describe('Broker::Carriers::Users') do
  let(:broker_carrier) { create(:broker_carrier, carrier:) }
  let(:carrier) { create(:carrier, name: 'Acme Freight') }
  let(:current_user) { create(:root_broker_user) }

  before do
    seed_settings
    sign_in(current_user)
  end

  describe 'GET /broker/carriers/:carrier_id/users' do
    let!(:carrier_user) { create(:carrier_user, companyable: carrier) }
    let!(:contact) { create(:contact, companyable: carrier, email: 'billing@acme.test', first_name: 'Billie') }

    before { get("/broker/carriers/#{broker_carrier.carrier_id}/users") }

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(assigns(:users)).to(contain_exactly(carrier_user)) }
    it { expect(assigns(:uninvited_contacts)).to(contain_exactly(contact)) }
    it { expect(response.body).to(include("contact_id=#{contact.id}")) }
  end
end
