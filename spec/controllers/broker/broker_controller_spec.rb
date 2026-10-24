require 'rails_helper'

RSpec.describe(Broker::BrokerController) do
  subject { response }

  let(:current_user) { create(:root_broker_user) }

  before { sign_in(current_user) }

  describe 'GET #settings' do
    let(:broker_country) { BrokerCountry.create!(country: create(:country)) }
    let!(:setting) { create(:setting, key: 'phone', value: '+15035550100') }

    before do
      broker_country
      get(:settings)
    end

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(assigns(:broker_countries)).to(contain_exactly(broker_country)) }
    it { expect(assigns(:settings)).to(eq('phone' => setting)) }

    context 'when a customer user' do
      let(:current_user) { create(:customer_user) }

      it { is_expected.to(have_http_status(:not_found)) }
    end
  end
end
