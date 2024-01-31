# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(BrokerCustomer::ProfitabilityReportJsonService) do
  let(:broker_customer) { create(:broker_customer) }
  let(:picked_up_at) { 14.days.ago }
  let!(:shipment) do
    create(
      :shipment,
      broker_customer: broker_customer,
      picked_up_at:,
      carrier_cost_cents: 1000,
carrier_cost_currency: 'USD',
      carrier_charge_cents: 1500,
carrier_charge_currency: 'USD',
    )
  end

  let(:from_date) { nil }
  let(:to_date) { nil }

  let(:expected_json) do
    {
      total_shipments: 1,
      total_cost: Money.new(1000),
      total_charges: Money.new(1500),
      total_profit: Money.new(500),
      total_margin: 33.3
    }
  end

  before { Timecop.freeze(Time.zone.now) }

  after { Timecop.return }

  describe '#call' do
    subject { described_class.new(broker_customer:, from_date:, to_date:).call }

    context 'when from_date and to_date are blank' do
      context 'and broker customer shipments is blank' do
        it 'does not persist' do
          expect(broker_customer).to(receive(:shipments).and_return([]))

          expect(subject).to(be_nil)
        end
      end

      context 'and broker customer shipments is blank' do
        it 'returns json report' do
          expect(subject).to(eq(expected_json))
        end
      end
    end

    context 'when from date and to date are present' do
      let(:from_date) { picked_up_at.beginning_of_month }
      let(:to_date) { picked_up_at.end_of_month }

      before { create(:shipment, broker_customer:, picked_up_at: 1.year.ago) }

      it 'only includes shipment where picked_up_at is between the from and to date' do
        expect(subject).to(eq(expected_json))
      end
    end
  end
end
