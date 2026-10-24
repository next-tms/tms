require 'rails_helper'

RSpec.describe(Broker::SettingsController) do
  subject { response }

  let(:current_user) { create(:root_broker_user) }

  before { sign_in(current_user) }

  describe 'GET #new' do
    before { get(:new, params: { key: 'mailing_address' }) }

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(assigns(:setting).key).to(eq('mailing_address')) }
  end

  describe 'POST #create' do
    let(:region) { create(:region) }
    let(:address_attributes) { { city: 'Portland', country_id: region.country_id, region_id: region.id, street: '123 Main St', zip_code: '97201' } }

    before { post(:create, params: { setting: { address_attributes:, key: 'mailing_address' } }) }

    it { is_expected.to(redirect_to([ :broker, Setting.last ])) }
    it { expect(Setting.mailing_address!).to(have_attributes(city: 'Portland', street: '123 Main St')) }
  end

  describe 'PATCH #update' do
    let(:setting) { create(:setting, key: 'mailing_address', value: create(:address).id.to_s) }

    before { patch(:update, params: { id: setting.id, setting: { address_attributes: { city: 'Salem' } } }) }

    it { is_expected.to(redirect_to(broker_settings_path)) }
    it { expect(Setting.mailing_address!.city).to(eq('Salem')) }
  end
end
