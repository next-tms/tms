# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BrokerCustomer::CarrierChargeCalculatorService do
  let(:broker_customer) { create(:broker_customer, default_upcharge_cents: 100) }
  let!(:shipment) do
    create(:shipment,
           broker_customer: broker_customer,
           carrier_cost_cents: 1000, carrier_cost_currency: "USD",
           carrier_charge_cents: 1500, carrier_charge_currency: "USD")
  end

  let!(:upcharge_rule) { create(:upcharge_rule, broker_customer:, min: 1, upcharge_percentage: 5) }

  let!(:item) do
    create(:item, quantity: 1).tap do |i|
      shipment.items << i
      shipment.save
    end
  end

  let(:carrier_cost) { nil }

  describe '#call' do
    subject { described_class.new(broker_customer:, carrier_cost:, shipment:).call }

    context 'when carrier_cost is blank' do
      it { expect(subject).to be_nil }
    end

    context 'when carrier_cost is negative' do
      let(:carrier_cost) { -1 }

      it { expect(subject).to be_nil }
    end

    context 'when carrier_cost is positive' do
      let(:carrier_cost) { Money.new(100) }

      context 'and default_upcharge and upcharge_rules are blank' do
        before do
          expect(broker_customer).to receive(:default_upcharge).and_return(nil)
          expect(broker_customer).to receive(:upcharge_rules).and_return([])
        end
  
        it { expect(subject).to be_nil }
      end

      context 'and upcharge_rules are blank and default_upcharge is positive' do
        before do
          expect(broker_customer).to receive(:upcharge_rules).and_return([])
        end
        
        it 'returns sum of carrier_cost and default_upcharge' do
          expect(subject).to eq(Money.new(200))
        end
      end

      context 'and upcharge_rules are present' do
        context 'and shipment items differ packaging id with upcharge rules' do
          context 'and default_upcharge and default_upcharge_percentage is negative' do
            before do
              expect(broker_customer).to receive(:default_upcharge).twice.and_return(0)
              expect(broker_customer).to receive(:default_upcharge_percentage).and_return(0)
            end

            it { expect(subject).to be_nil }
          end

          context 'and default_upcharge_percentage is negative' do
            before do
              expect(broker_customer).to receive(:default_upcharge_percentage).and_return(0)
            end

            it 'returns sum of carrier_cost and default_upcharge' do
              expect(subject).to eq(Money.new(200))
            end
          end

          context 'and default_upcharge_percentage is positive' do
            before do
              expect(broker_customer).to receive(:default_upcharge_percentage).twice.and_return(10)
            end

            it 'returns sum of carrier_cost and default_upcharge plus percentage from carrier_cost' do
              expect(subject).to eq(Money.new(210))
            end
          end
        end

        context 'and shipment items are mapped based from packaging id and min and max' do
          before { item.update(packaging: upcharge_rule.packaging) }

          it 'returns carrier cost + upcharge percentage with additional upcharge per item quantity' do
            # Carrier cost = $100
            # Item Quantity = 1 * 5.0 = $1
            # Upcharge Percentage = 5% (5% of Carrier Cost) = $5
            expect(subject).to eq(Money.new(106))
          end
        end
      end
    end
  end
end
