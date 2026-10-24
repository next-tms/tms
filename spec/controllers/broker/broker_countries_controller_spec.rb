require 'rails_helper'

RSpec.describe(Broker::BrokerCountriesController) do
  subject { response }

  let(:current_user) { create(:root_broker_user) }

  before { sign_in(current_user) }

  describe 'POST #create' do
    let(:country) { create(:country) }

    before { post(:create, params: { broker_country: { country_id: country.id } }) }

    it { is_expected.to(redirect_to(broker_settings_company_path)) }
    it { expect(BrokerCountry.pluck(:country_id)).to(eq([ country.id ])) }

    context 'when the country is already serviced' do
      before { post(:create, params: { broker_country: { country_id: country.id } }) }

      it { expect(flash[:error]).to(eq('Unable to add country')) }
      it { expect(BrokerCountry.count).to(eq(1)) }
    end
  end

  describe 'DELETE #destroy' do
    let(:broker_country) { BrokerCountry.create!(country: create(:country)) }

    before { delete(:destroy, params: { id: broker_country.id }) }

    it { is_expected.to(redirect_to(broker_settings_company_path)) }
    it { expect(BrokerCountry.exists?(broker_country.id)).to(be(false)) }
  end
end
