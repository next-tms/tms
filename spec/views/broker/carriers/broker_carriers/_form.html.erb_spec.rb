require 'rails_helper'

RSpec.describe('broker/carriers/broker_carriers/_form') do
  subject { rendered }

  let(:assigned_carrier) { carrier }
  let(:broker_carrier) { create(:broker_carrier, carrier:, check_mailing_address: create(:address)) }
  let(:carrier) { create(:carrier, :saia) }

  before do
    assign(:broker_carrier, broker_carrier)
    assign(:carrier, assigned_carrier)
    render(partial: 'broker/carriers/broker_carriers/form', locals: { url: '/' })
  end

  it { is_expected.not_to(have_field('broker_carrier[carrier_id]')) }
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

  context 'when adding a carrier' do
    let(:assigned_carrier) { nil }

    it { is_expected.to(have_select('broker_carrier[carrier_id]', with_options: [carrier.name])) }
  end

  context 'when the carrier is custom' do
    let(:carrier) { create(:carrier) }

    it { is_expected.not_to(have_field('broker_carrier[website_username]')) }
  end
end
