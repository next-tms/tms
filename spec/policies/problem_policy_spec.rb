require 'rails_helper'

RSpec.describe(ProblemPolicy) do
  let(:authorizable) { create(:broker_user).tap { |broker_user| broker_user.add_role(:dispatch) } }
  let(:policy) { described_class.new(problem, authorizable:) }
  let(:problem) { create(:problem, problematic_rule_code: 'missing_carrier_pod') }

  describe '#apply_scope' do
    subject { policy.apply_scope(Problem.all, type: :active_record_relation) }

    let!(:dispatch_problem) { create(:problem, problematic_rule_code: 'lost') }

    before { problem }

    it { is_expected.to(include(dispatch_problem, problem)) }

    context 'with an accounts receivable user' do
      let(:authorizable) { create(:broker_user).tap { |broker_user| broker_user.add_role(:accounts_receivable) } }

      it { is_expected.to(include(problem)) }
      it { is_expected.not_to(include(dispatch_problem)) }
    end

    context 'with a carrier user' do
      let(:authorizable) { create(:carrier_user) }

      it { is_expected.to(be_empty) }
    end

    context 'with a customer user' do
      let(:authorizable) { create(:customer_user) }

      it { is_expected.to(be_empty) }
    end
  end

  describe '#view?' do
    subject { policy.apply(:view?) }

    it { is_expected.to(be(true)) }

    context 'with a broker user without a matching role' do
      let(:authorizable) { create(:broker_user).tap { |broker_user| broker_user.add_role(:accounts_payable) } }

      it { is_expected.to(be(false)) }
    end

    context 'with a customer user' do
      let(:authorizable) { create(:customer_user) }

      it { is_expected.to(be(false)) }
    end

    context 'without a record' do
      let(:problem) { nil }

      it { is_expected.to(be(false)) }
    end
  end
end
