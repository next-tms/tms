require 'rails_helper'

RSpec.describe(Types::RateType) do
  subject(:rate_type) { described_class.authorized_new(build(:rate, breakdown:), GraphQL::Query.new(LiftoffSchema, nil, context: {}).context) }

  let(:breakdown) { [{ 'cost' => { 'fractional' => 100 }, 'description' => 'Linehaul' }] }

  describe '#breakdown' do
    subject { rate_type.breakdown }

    it { is_expected.to(eq(breakdown)) }

    context 'with a blank breakdown' do
      let(:breakdown) { '' }

      it { is_expected.to(be_nil) }
    end
  end
end
