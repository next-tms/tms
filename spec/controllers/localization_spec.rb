require 'rails_helper'

RSpec.describe(Localization) do
  controller(ActionController::Base) do
    include Localization # rubocop:disable RSpec/DescribedClass

    def index = render(plain: [I18n.locale, Address.human_attribute_name(:country_alpha2), I18n.t(:app_name)].join('|'))
  end

  before do
    request.headers['Accept-Language'] = accept_language
    get(:index)
  end

  context 'with a language region the app does not ship' do
    let(:accept_language) { 'es-MX,es;q=0.9' }

    it { expect(response.body).to(start_with('es|')) }
  end

  context 'with a missing translation' do
    let(:accept_language) { 'es' }

    it { expect(response.body).to(end_with("|#{I18n.t(:app_name, locale: :en)}")) }
  end

  context 'with a rejected language' do
    let(:accept_language) { 'es;q=0, eo;q=0.5' }

    it { expect(response.body).to(start_with('eo|')) }
  end

  context 'with a translated attribute' do
    let(:accept_language) { 'es' }

    it { expect(response.body).to(include("|#{I18n.t('activerecord.attributes.address.country_alpha2', locale: :es)}|")) }
  end

  context 'with an exact regional locale' do
    let(:accept_language) { 'zh-tw' }

    it { expect(response.body).to(start_with('zh-TW|')) }
  end

  context 'with an unsupported language' do
    let(:accept_language) { 'fr-FR,fr;q=0.9' }

    it { expect(response.body).to(start_with('en|')) }
  end

  context 'with no header' do
    let(:accept_language) { nil }

    it { expect(response.body).to(start_with('en|')) }
  end

  context 'with quality values' do
    let(:accept_language) { 'fr;q=0.9, eo;q=0.5, es;q=0.8' }

    it { expect(response.body).to(start_with('es|')) }
  end

  context 'with the response headers' do
    let(:accept_language) { 'es' }

    it { expect(response.headers['Vary']).to(include('Accept-Language')) }
  end
end
