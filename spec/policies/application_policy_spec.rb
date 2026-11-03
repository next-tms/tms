require 'rails_helper'

RSpec.describe(ApplicationPolicy) do
  let(:policy) { policy_class.new(nil, authorizable:) }

  let(:policy_class) do
    Class.new(described_class) do
      def broker_carrier_rule? = broker_carrier?
      def broker_rule? = broker?
      def carrier_rule? = carrier?
      def customer_rule? = customer?
      def user_rule? = user?

      public :companyable
    end
  end

  describe '.authorization_targets' do
    it { expect(described_class.authorization_targets.keys).to(eq([:authorizable])) }
    it { expect { described_class.new(nil, user: build(:broker_user)) }.to(raise_error(ActionPolicy::AuthorizationContextMissing)) }
  end

  describe '#broker?' do
    subject { policy.apply(:broker_rule?) }

    context 'when not authorizable.is_a?(User)' do
      let(:authorizable) { build(:customer) }

      it { is_expected.to(be(false)) }
    end

    context 'when user.broker?' do
      let(:authorizable) { build(:broker_user) }

      it { is_expected.to(be(true)) }
    end

    context 'when user.customer?' do
      let(:authorizable) { build(:customer_user) }

      it { is_expected.to(be(false)) }
    end
  end

  describe '#broker_carrier?' do
    subject { policy.apply(:broker_carrier_rule?) }

    context 'when authorizable.is_a?(BrokerCarrier)' do
      let(:authorizable) { build(:broker_carrier) }

      it { is_expected.to(be(true)) }
    end

    context 'when user.carrier?' do
      let(:authorizable) { build(:user, companyable: build(:broker_carrier)) }

      it { is_expected.to(be(false)) }
    end
  end

  describe '#carrier?' do
    subject { policy.apply(:carrier_rule?) }

    context 'when authorizable.is_a?(BrokerCarrier)' do
      let(:authorizable) { build(:broker_carrier) }

      it { is_expected.to(be(true)) }
    end

    context 'when not authorizable.is_a?(User)' do
      let(:authorizable) { build(:customer) }

      it { is_expected.to(be(false)) }
    end

    context 'when user.broker?' do
      let(:authorizable) { build(:broker_user) }

      it { is_expected.to(be(false)) }
    end

    context 'when user.carrier?' do
      let(:authorizable) { build(:user, companyable: build(:broker_carrier)) }

      it { is_expected.to(be(true)) }
    end
  end

  describe '#companyable' do
    subject { policy.companyable }

    context 'when authorizable.is_a?(BrokerCarrier)' do
      let(:authorizable) { build(:broker_carrier) }

      it { is_expected.to(be(authorizable)) }
    end

    context 'when user.customer?' do
      let(:authorizable) { build(:customer_user) }

      it { is_expected.to(be(authorizable.companyable)) }
    end
  end

  describe '#create?' do
    let(:authorizable) { build(:broker_user) }

    it { expect(policy.apply(:create?)).to(be(false)) }
    it { expect(policy.apply(:new?)).to(be(false)) }
  end

  describe '#customer?' do
    subject { policy.apply(:customer_rule?) }

    context 'when not authorizable.is_a?(User)' do
      let(:authorizable) { build(:customer) }

      it { is_expected.to(be(false)) }
    end

    context 'when user.broker?' do
      let(:authorizable) { build(:broker_user) }

      it { is_expected.to(be(false)) }
    end

    context 'when user.customer?' do
      let(:authorizable) { build(:customer_user) }

      it { is_expected.to(be(true)) }
    end
  end

  describe '#index?' do
    let(:authorizable) { build(:broker_user) }

    it { expect(policy.apply(:index?)).to(be(false)) }
  end

  describe '#manage?' do
    let(:authorizable) { build(:broker_user) }

    it { expect(policy.apply(:manage?)).to(be(false)) }
    it { expect(policy.apply(:edit?)).to(be(false)) }
    it { expect(policy.resolve_rule(:edit?)).to(eq(:manage?)) }
    it { expect(policy.resolve_rule(:new?)).to(eq(:create?)) }
  end

  describe '#user?' do
    subject { policy.apply(:user_rule?) }

    context 'when authorizable.is_a?(User)' do
      let(:authorizable) { build(:broker_user) }

      it { is_expected.to(be(true)) }
    end

    context 'when not authorizable.is_a?(User)' do
      let(:authorizable) { build(:customer) }

      it { is_expected.to(be(false)) }
    end
  end
end
