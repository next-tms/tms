require 'rails_helper'

RSpec.describe('broker/broker_carriers/tariff') do
  subject { rendered }

  let(:broker_carrier) { create(:broker_carrier, carrier:, password: 'secret', username: 'user') }
  let(:carrier) { create(:carrier, :saia) }

  before do
    assign(:broker_carrier, broker_carrier)
    stub_template('broker/broker_carriers/_member_header.html.erb' => '')
    render
  end

  it { is_expected.to(include('Nothing to configure')) }

  context 'when the carrier API does not handle overlength fees' do
    let(:broker_carrier) { create(:broker_carrier, carrier:, encrypted_api_key: 'key') }
    let(:carrier) { create(:carrier, :tql) }

    it { is_expected.to(include('name="broker_carrier[overlength_rules_attributes][NEW_RECORD][min_length]"')) }
    it { is_expected.not_to(include('pricing_rules_attributes')) }
  end

  context 'when the carrier is custom' do
    let(:carrier) { create(:carrier) }

    it { is_expected.to(include('pricing_rules_attributes')) }
  end
end
