require 'rails_helper'

RSpec.describe(Broker::BrokerCountriesController) do
  subject { response }

  let(:current_user) { create(:root_broker_user) }

  before { sign_in(current_user) }

  describe 'POST #create' do
    before { post(:create, params: { broker_country: { country_alpha2: 'CA' } }) }

    it { is_expected.to(redirect_to(broker_settings_company_path)) }
    it { expect(BrokerCountry.pluck(:country_alpha2)).to(eq([ 'CA' ])) }

    context 'when the country is already serviced' do
      before { post(:create, params: { broker_country: { country_alpha2: 'CA' } }) }

      it { expect(flash[:error]).to(eq('Unable to add country')) }
      it { expect(BrokerCountry.count).to(eq(1)) }
    end

    context 'when the country is not a known code' do
      before { post(:create, params: { broker_country: { country_alpha2: 'ZZ' } }) }

      it { expect(flash[:error]).to(eq('Unable to add country')) }
      it { expect(BrokerCountry.pluck(:country_alpha2)).to(eq([ 'CA' ])) }
    end
  end

  describe 'DELETE #destroy' do
    let(:broker_country) { BrokerCountry.create!(country_alpha2: 'CA') }

    before { delete(:destroy, params: { id: broker_country.id }) }

    it { is_expected.to(redirect_to(broker_settings_company_path)) }
    it { expect(BrokerCountry.exists?(broker_country.id)).to(be(false)) }
  end
end
