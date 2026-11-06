require 'rails_helper'

RSpec.describe BrokerCustomer::ProfitabilityReportJsonService do
  describe '#call' do
    subject(:report) { described_class.new(broker_customer:, from_date: Date.current - 1, to_date: Date.current + 1).call }

    let(:broker_customer) { create(:broker_customer) }
    let(:shipment) { create(:shipment, broker_customer:, picked_up_at: Time.current) }
    let(:total_charges_cents) { 1_000 }

    before do
      create(:setting, key: 'time_zone_name', value: 'America/Los_Angeles')
      shipment.update_columns(total_charges_cents:, total_charges_currency: 'USD', total_cost_cents: 750, total_cost_currency: 'USD') # rubocop:disable Rails/SkipsModelValidations
    end

    it { expect(report[:total_margin]).to(eq(25.0)) }

    context 'without charges' do
      let(:total_charges_cents) { 0 }

      it { expect(report[:total_margin]).to(be_nil) }
    end
  end
end
