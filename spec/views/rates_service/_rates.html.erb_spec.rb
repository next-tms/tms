require 'rails_helper'

RSpec.describe('rates_service/_rates') do
  subject { rendered }

  let(:broker_carrier) { create(:broker_carrier, carrier:, password: 'secret', username: 'user') }
  let(:carrier) { create(:carrier, :saia) }
  let(:rate) { create(:rate, broker_carrier:, cost_cents: 10_000, cost_currency: 'USD', shipment:, tracking_carrier_id: nil) }
  let(:shipment) do
    create(
      :shipment,
      broker_carrier:,
      carrier_charge_currency: 'USD',
      carrier_cost_currency: 'USD',
      pro: '12345678901',
      total_charges_currency: 'USD',
      total_cost_currency: 'USD',
      value_currency: 'USD'
    )
  end

  before { render(partial: 'rates_service/rates', locals: { rates: [rate], shipment:, user_type: :broker }) }

  it { is_expected.to(have_link('Dispatch')) }

  context 'when the carrier API cannot create pickups' do
    let(:broker_carrier) { create(:broker_carrier, carrier:, encrypted_api_key: 'key') }
    let(:carrier) { create(:carrier, :tql) }

    it { is_expected.not_to(have_link('Dispatch')) }
  end

  context 'when the carrier is custom' do
    let(:carrier) { create(:carrier) }

    it { is_expected.not_to(have_link('Dispatch')) }
  end
end
