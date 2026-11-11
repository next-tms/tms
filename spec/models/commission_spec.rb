require 'rails_helper'

RSpec.describe Commission do
  describe '#percent' do
    let(:commission) { described_class.new(amount: Money.new(500, 'USD'), shipment:) }
    let(:shipment) { Shipment.new(total_charges: Money.new(2_000, 'USD'), total_cost: Money.new(1_000, 'USD')) }

    it { expect(commission.percent).to(eq(0.5)) }

    context 'without profit' do
      before { shipment.total_cost = shipment.total_charges }

      it { expect(commission.percent).to(eq(0)) }
    end
  end
end
