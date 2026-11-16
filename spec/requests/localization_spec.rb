require 'rails_helper'

RSpec.describe('Localization') do
  let(:accept_language) { 'es-MX,es;q=0.9' }
  let(:current_user) { create(:root_broker_user, locale:) }
  let(:locale) { nil }

  before { seed_settings }

  describe 'GET with an Accept-Language header' do
    before do
      sign_in(current_user)
      get(broker_shipments_path, headers: { 'Accept-Language' => accept_language })
    end

    it { expect(response.body).to(include('<html lang="es">')) }
    it { expect(current_user.reload.locale).to(eq('es')) }

    context 'with a saved locale' do
      let(:locale) { 'eo' }

      it { expect(response.body).to(include('<html lang="eo">')) }
      it { expect(current_user.reload.locale).to(eq('eo')) }
    end

    context 'with an unsupported language' do
      let(:accept_language) { 'fr' }

      it { expect(response.body).to(include('<html lang="en">')) }
      it { expect(current_user.reload.locale).to(be_nil) }
    end
  end

  describe 'GET with a lang parameter' do
    before do
      sign_in(current_user)
      get(broker_shipments_path, headers: { 'Accept-Language' => accept_language }, params: { lang: 'zh-TW' })
    end

    it { expect(response.body).to(include('<html lang="zh-TW">')) }
    it { expect(current_user.reload.locale).to(eq('zh-TW')) }

    context 'with a saved locale' do
      let(:locale) { 'eo' }

      it { expect(current_user.reload.locale).to(eq('zh-TW')) }
    end

    context 'with an unsupported language' do
      before { get(broker_shipments_path, params: { lang: 'fr' }) }

      it { expect(current_user.reload.locale).to(eq('zh-TW')) }
    end
  end

  describe 'GET with a lang parameter before signing in' do
    before do
      get(new_user_session_path, params: { lang: 'eo' })
      sign_in(current_user)
      get(broker_shipments_path, headers: { 'Accept-Language' => accept_language })
    end

    it { expect(response.body).to(include('<html lang="eo">')) }
    it { expect(current_user.reload.locale).to(eq('eo')) }
  end

  describe 'GET while impersonating' do
    let(:customer_user) { create(:customer_user) }

    before do
      sign_in(current_user)
      post("/broker/users/#{customer_user.id}/impersonate")
      get(customer_root_path, headers: { 'Accept-Language' => accept_language }, params: { lang: 'eo' })
    end

    it { expect(customer_user.reload.locale).to(be_nil) }
  end

  describe 'footer' do
    let(:locale) { 'es' }

    before do
      sign_in(current_user)
      get(broker_shipments_path, params: { page: 2 })
    end

    it { expect(response.body).to(include('<a hreflang="eo" lang="eo" href="/broker/shipments?lang=eo&amp;page=2">Esperanto</a>')) }
    it { expect(response.body).not_to(include('hreflang="es"')) }
  end
end
