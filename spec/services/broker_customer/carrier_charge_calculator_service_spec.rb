require 'rails_helper'

RSpec.describe BrokerCustomer::CarrierChargeCalculatorService do
  let(:broker_customer) { create(:broker_customer, default_upcharge_cents: 100) }
  let!(:shipment) do
    create(:shipment,
           broker_customer:,
           carrier_cost_cents: 1000, carrier_cost_currency: 'USD',
           carrier_charge_cents: 1500, carrier_charge_currency: 'USD')
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
    subject(:call) { described_class.new(broker_customer:, carrier_cost:, shipment:).call }

    context 'when carrier_cost is blank' do
      it { is_expected.to be_nil }
    end

    context 'when carrier_cost is negative' do
      let(:carrier_cost) { -1 }

      it { is_expected.to be_nil }
    end

    context 'when carrier_cost is positive' do
      let(:carrier_cost) { Money.new(100) }

      context 'when default_upcharge and upcharge_rules are blank' do
        before { allow(broker_customer).to receive_messages(default_upcharge: nil, upcharge_rules: []) }

        it { is_expected.to be_nil }
      end

      context 'when upcharge_rules are blank and default_upcharge is positive' do
        before { allow(broker_customer).to receive(:upcharge_rules).and_return([]) }

        it { is_expected.to eq(Money.new(200)) }
      end

      context 'when upcharge_rules are present' do
        context 'when shipment items differ packaging id with upcharge rules' do
          context 'when default_upcharge and default_upcharge_percentage are negative' do
            before do
              allow(broker_customer).to receive(:default_upcharge).twice.and_return(0)
              allow(broker_customer).to receive(:default_upcharge_percentage).and_return(0)
            end

            it { is_expected.to be_nil }
          end

          context 'when default_upcharge_percentage is negative' do
            before { allow(broker_customer).to receive(:default_upcharge_percentage).and_return(0) }

            it { is_expected.to eq(Money.new(200)) }
          end

          context 'when default_upcharge_percentage is positive' do
            before { allow(broker_customer).to receive(:default_upcharge_percentage).twice.and_return(10) }

            it { is_expected.to eq(Money.new(210)) }
          end
        end

        context 'when shipment items are mapped based from packaging id and min and max' do
          before { item.update(packaging: upcharge_rule.packaging) }

          it { is_expected.to eq(Money.new(106)) }
        end
      end
    end
  end
end
