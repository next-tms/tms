require 'rails_helper'

RSpec.describe('Broker::BrokerCustomers profitability report') do
  let(:broker_customer) { create(:broker_customer) }
  let(:shipment) { create(:shipment, broker_customer:, picked_up_at: Time.current) }

  before do
    seed_settings
    sign_in(create(:root_broker_user))
    shipment.update_columns(total_charges_cents:, total_charges_currency: 'USD', total_cost_cents: 750, total_cost_currency: 'USD') # rubocop:disable Rails/SkipsModelValidations
    get('/broker/customers/profitability-report')
  end

  context 'with charges' do
    let(:total_charges_cents) { 1_000 }

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(response.body).to(include('25.0%')) }
  end

  context 'without charges' do
    let(:total_charges_cents) { 0 }

    it { is_expected.to(have_http_status(:ok)) }
    it { expect(response.body).not_to(include('Infinity')) }
  end
end
