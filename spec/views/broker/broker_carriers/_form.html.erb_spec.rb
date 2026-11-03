require 'rails_helper'

RSpec.describe('broker/broker_carriers/_form') do
  subject { rendered }

  let(:broker_carrier) { create(:broker_carrier, carrier:, check_mailing_address: create(:address)) }
  let(:carrier) { create(:carrier, :saia) }

  before do
    assign(:broker_carrier, broker_carrier)
    render(partial: 'broker/broker_carriers/form')
  end

  it { is_expected.to(have_field('broker_carrier[username]')) }
  it { is_expected.to(have_field('broker_carrier[password]')) }
  it { is_expected.not_to(have_field('broker_carrier[encrypted_api_key]')) }
  it { is_expected.to(have_field('broker_carrier[ignore_bol_requires_tracking_number]')) }

  context 'when the carrier needs an API key' do
    let(:carrier) { create(:carrier, :tql) }

    it { is_expected.to(have_field('broker_carrier[encrypted_api_key]')) }
    it { is_expected.not_to(have_field('broker_carrier[username]')) }
    it { is_expected.not_to(have_field('broker_carrier[ignore_bol_requires_tracking_number]')) }
  end

  context 'when the carrier is custom' do
    let(:carrier) { create(:carrier) }

    it { is_expected.not_to(have_field('broker_carrier[website_username]')) }
  end
end
