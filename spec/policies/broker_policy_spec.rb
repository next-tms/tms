require 'rails_helper'

RSpec.describe(BrokerPolicy) do
  let(:policy) { described_class.new(build(:shipment), user:) }

  describe '#show?' do
    subject { policy.apply(:show?) }

    context 'when user.broker?' do
      let(:user) { build(:broker_user) }

      it { is_expected.to(be(true)) }
    end

    context 'when not user.broker?' do
      let(:user) { build(:customer_user) }

      it { is_expected.to(be(false)) }
    end
  end
end
