require 'rails_helper'

RSpec.describe(Broker::SettingsController) do
  let(:current_user) { create(:root_broker_user) }

  before { sign_in(current_user) }

  describe '#setting_params' do
    subject { controller.__send__(:setting_params).to_h }

    let(:attributes) { { address_attributes: { city: 'Portland' }, key: 'mailing_address' } }

    before { controller.params = { setting: attributes } }

    it { is_expected.to(eq(attributes.deep_stringify_keys)) }
  end

  describe 'GET #new' do
    before { get(:new, params: { key: 'mailing_address' }) }

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(assigns(:setting).key).to(eq('mailing_address')) }
  end

  describe 'POST #create' do
    let(:address_attributes) do
      { city: 'Portland', country_alpha2: 'US', region_iso31662: 'US-CA', street: '123 Main St', zip_code: '97201' }
    end

    before { post(:create, params: { setting: { address_attributes:, key: 'mailing_address' } }) }

    it { is_expected.to(redirect_to([:broker, Setting.last])) }
    it { expect(Setting.mailing_address!).to(have_attributes(city: 'Portland', street: '123 Main St')) }
  end

  describe 'PATCH #update' do
    let(:setting) { create(:setting, key: 'mailing_address', value: create(:address).id.to_s) }

    before { patch(:update, params: { id: setting.id, setting: { address_attributes: { city: 'Salem' } } }) }

    it { is_expected.to(redirect_to(broker_settings_path)) }
    it { expect(Setting.mailing_address!.city).to(eq('Salem')) }
  end
end
