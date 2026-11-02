require 'rails_helper'

RSpec.describe(APIKeyPolicy) do
  let(:api_key) { create(:api_key, authorizable: user) }
  let(:carrier_api_key) { create(:api_key, :broker_carrier) }
  let(:policy) { described_class.new(api_key, user:) }
  let(:user) { create(:customer_user) }

  describe '#apply_scope' do
    subject { policy.apply_scope(APIKey.all, type: :active_record_relation) }

    before do
      api_key
      carrier_api_key
      create(:api_key)
    end

    it { is_expected.to(contain_exactly(api_key)) }

    context 'when an accounts payable broker lists keys' do
      let(:user) { create(:root_broker_user) }

      it { is_expected.to(contain_exactly(api_key, carrier_api_key)) }
    end
  end

  describe '#manage?' do
    subject { policy.apply(:manage?) }

    it { is_expected.to(be(true)) }

    context 'when the key belongs to another user' do
      let(:policy) { described_class.new(create(:api_key), user:) }

      it { is_expected.to(be(false)) }
    end

    context 'when a customer manages a carrier key' do
      let(:policy) { described_class.new(carrier_api_key, user:) }

      it { is_expected.to(be(false)) }
    end

    context 'when an accounts payable broker manages a carrier key' do
      let(:policy) { described_class.new(carrier_api_key, user:) }
      let(:user) { create(:root_broker_user) }

      it { is_expected.to(be(true)) }
    end
  end

  describe '#view?' do
    subject { policy.apply(:view?) }

    it { is_expected.to(be(true)) }

    context 'when the key belongs to another user' do
      let(:policy) { described_class.new(create(:api_key), user:) }

      it { is_expected.to(be(false)) }
    end
  end
end
