require 'rails_helper'

RSpec.describe(TransponderService::Input::Carrier) do
  let(:account) { Faker::Alphanumeric.alphanumeric(number: 10, min_alpha: 3, min_numeric: 3).upcase }
  let(:api_credentials) { [Faker::Internet.username, Faker::Internet.password] }
  let(:encrypted_api_key) { Faker::Internet.password }
  let(:encrypted_proxy_url) { Faker::Internet.url }
  let(:website_credentials) { [Faker::Internet.username, Faker::Internet.password] }

  let(:carrier) { create(:carrier, encrypted_proxy_url:) }

  let(:object) do
    username, password = api_credentials
    website_username, website_password = website_credentials

    create(
      :broker_carrier,
      account:,
      carrier:,
      encrypted_api_key:,
      username:,
      password:,
      website_username:,
      website_password:
    )
  end

  let(:service) { described_class.new(object) }

  describe '#api_credential' do
    let!(:result) { service.__send__(:api_credential) }

    it { expect(result[:account]).to(eq(object.account)) }
    it { expect(result[:api_key]).to(eq(object.encrypted_api_key)) }
    it { expect(result[:password]).to(eq(object.password)) }
    it { expect(result[:type]).to(eq('api')) }
    it { expect(result[:username]).to(eq(object.username)) }

    context 'when object.carrier.api_key.present?' do
      let(:carrier) { create(:carrier, encrypted_api_key: Faker::Internet.password) }

      it { expect(result[:api_key]).to(eq(carrier.encrypted_api_key)) }
    end
  end

  describe '#api_key_credential' do
    let!(:result) { service.__send__(:api_key_credential) }

    it { expect(result[:account]).to(eq(object.account)) }
    it { expect(result[:api_key]).to(eq(object.encrypted_api_key)) }
    it { expect(result[:type]).to(eq('api_key')) }

    context 'when object.carrier.api_key.present?' do
      let(:carrier) { create(:carrier, encrypted_api_key: Faker::Internet.password) }

      it { expect(result[:api_key]).to(eq(carrier.encrypted_api_key)) }
    end
  end

  describe '#api_proxy_credential' do
    let!(:result) { service.__send__(:api_proxy_credential) }

    it { expect(result[:api_key]).to(eq(object.encrypted_api_key)) }
    it { expect(result[:proxy_url]).to(eq(carrier.encrypted_proxy_url)) }
    it { expect(result[:type]).to(eq('api_proxy')) }

    context 'when object.carrier.api_key.present?' do
      let(:carrier) do
        create(:carrier, encrypted_api_key: Faker::Internet.password, encrypted_proxy_url: Faker::Internet.url)
      end

      it { expect(result[:api_key]).to(eq(carrier.encrypted_api_key)) }
    end
  end

  describe '#build' do
    let(:customer_location) { Faker::Alphanumeric.alpha }
    let(:result) { service.build }

    before { allow(service).to(receive(:customer_location).and_return(customer_location)) }

    it { expect(result[:carrier_credentials]).to(eq(service.__send__(:carrier_credentials))) }
    it { expect(result[:customer_location]).to(eq(customer_location)) }
    it { expect(result[:scac]).to(eq(carrier.scac)) }
    it { expect(result[:tariff]).to(eq(service.__send__(:tariff))) }
  end

  describe '#selenoid_credential' do
    let!(:result) { service.__send__(:selenoid_credential) }

    it { expect(result[:type]).to(eq('selenoid')) }
  end

  describe '#website_credential' do
    let!(:result) { service.__send__(:website_credential) }

    it { expect(result[:account]).to(eq(object.account)) }
    it { expect(result[:password]).to(eq(object.website_password)) }
    it { expect(result[:type]).to(eq('website')) }
    it { expect(result[:username]).to(eq(object.website_username)) }
  end

  describe '#customer_location' do
    let(:address) { create(:address) }

    before do
      create(:setting, key: 'customer_service_email', value: 'help@acme.test')
      create(:setting, key: 'mailing_address', value: address.id.to_s)
      create(:setting, key: 'name', value: 'Acme Freight')
      create(:setting, key: 'phone', value: '+15035550100')
    end

    it {
      expect(service.__send__(:customer_location)).to(include('address1' => address.street, 'city' => address.city,
                                                              'postalCode' => address.zip_code))
    }

    it { expect(service.__send__(:customer_location)['contact']).to(include('companyName' => 'Acme Freight', 'email' => 'help@acme.test')) }
  end
end
