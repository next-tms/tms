require 'rails_helper'

RSpec.describe(Types::RateBreakdownType) do
  subject(:rate_breakdown) { described_class.authorized_new(line, GraphQL::Query.new(LiftoffSchema, nil, context: {}).context) }

  let(:line) { { 'blame' => 'carrier', 'cost' => { 'currency' => 'USD', 'fractional' => 12_345 }, 'description' => 'Fuel surcharge' } }

  describe '#cost_cents' do
    subject { rate_breakdown.cost_cents }

    it { is_expected.to(eq(12_345)) }

    context 'with legacy cents' do
      let(:line) { { 'cents' => 500, 'description' => 'Liftgate' } }

      it { is_expected.to(eq(500)) }
    end

    context 'with legacy cents as a value object' do
      let(:line) { { 'cents' => { 'value' => '750' }, 'description' => 'Liftgate' } }

      it { is_expected.to(eq(750)) }
    end

    context 'with symbol keys' do
      let(:line) { { cost: { currency: 'USD', fractional: 900 }, description: 'Linehaul' } }

      it { is_expected.to(eq(900)) }
    end

    context 'without an amount' do
      let(:line) { { 'description' => 'Note' } }

      it { is_expected.to(be_nil) }
    end
  end

  describe '#description' do
    subject { rate_breakdown.description }

    it { is_expected.to(eq('Fuel surcharge')) }

    context 'with symbol keys' do
      let(:line) { { description: 'Linehaul' } }

      it { is_expected.to(eq('Linehaul')) }
    end
  end
end
