require 'rails_helper'

RSpec.describe('Carrier::BrokerCarriers') do
  let(:broker_carrier) { create(:broker_carrier) }
  let(:carrier) { broker_carrier.carrier }
  let(:current_user) { create(:carrier_user, companyable: carrier) }

  before do
    seed_settings
    sign_in(current_user)
  end

  describe 'GET /carrier' do
    before { get('/carrier') }

    it { is_expected.to(redirect_to("/carrier/#{broker_carrier.id}/shipments")) }

    context 'with several accounts' do
      let(:broker_carrier) { create(:broker_carrier, broker_customer: create(:broker_customer)) }

      before do
        create(:broker_carrier, carrier:)
        get('/carrier')
      end

      it { is_expected.to(have_http_status(:ok)) }
      it { expect(assigns(:broker_carriers)).to(match_array(carrier.broker_carriers)) }
      it { expect(response.body).to(include(broker_carrier.broker_customer.customer.name)) }
    end

    context 'when signed in as a customer' do
      let(:current_user) { create(:customer_user) }

      it { is_expected.to(have_http_status(:not_found)) }
    end
  end
end
