require 'rails_helper'

RSpec.describe(ProblematicService::Rule) do
  describe 'class methods' do
    subject { described_class }

    it { is_expected.to(respond_to(:all)) }
    it { is_expected.to(respond_to(:code)) }
    it { is_expected.to(respond_to(:model)) }
  end

  describe '#call' do
    subject(:call) { rule.call(shipment) }

    let!(:other_problem) do
      create(:problem, problematic_rule_code: 'missing_broker_carrier_id', resolvable: shipment, resolved_at: other_problem_resolved_at)
    end
    let(:other_problem_resolved_at) { nil }
    let(:rule) { ProblematicService::Rule::Shipment::MissingPickedUpAt.new(ProblematicService::Processor::Shipment) }
    let(:rule_problems) { shipment.problems.where(problematic_rule_code: rule.code) }
    let(:shipment) { create(:shipment, updated_by:).tap { |shipment| shipment.problems.destroy_all } }
    let(:updated_by) { create(:broker_user) }

    context 'when not problematic or resolvable' do
      let!(:problem) { create(:problem, problematic_rule_code: rule.code, resolvable: shipment, resolved_at: 1.day.ago) }

      before { allow(rule).to(receive_messages(problematic?: false, resolvable?: false)) }

      it { expect { call }.not_to(change(rule_problems, :count)) }
      it { expect { call }.not_to(change { problem.reload.resolved? }) }
    end

    context 'when problematic' do
      before { allow(rule).to(receive_messages(problematic?: true, resolvable?: false)) }

      it { expect { call }.to(change { rule_problems.unresolved.count }.from(0).to(1)) }

      context 'when another rule has a resolved problem' do
        let(:other_problem_resolved_at) { 1.day.ago }

        it { expect { call }.not_to(change { other_problem.reload.resolved? }) }
      end

      context 'when the rule has a resolved problem' do
        let!(:problem) { create(:problem, problematic_rule_code: rule.code, resolvable: shipment, resolved_at: 1.day.ago) }

        it { expect { call }.to(change { problem.reload.resolved? }.from(true).to(false)) }
      end
    end

    context 'when resolvable' do
      let!(:problem) { create(:problem, problematic_rule_code: rule.code, resolvable: shipment) }

      before { allow(rule).to(receive(:resolvable?).and_return(true)) }

      it { expect { call }.to(change { problem.reload.resolved? }.from(false).to(true)) }
      it { expect { call }.to(change { problem.reload.resolved_by }.from(nil).to(updated_by)) }
      it { expect { call }.not_to(change { other_problem.reload.resolved? }) }
    end
  end

  describe '#assign' do
    subject(:assigned_to) { ProblematicService::Rule::Shipment::MissingChargesConfirmed.new(nil).with(shipment).__send__(:assign) }

    let(:shipment) { build(:shipment).tap { |record| record.dispatcher = nil } }
    let!(:staff_user) { create(:broker_user).tap { |user| user.add_role(:accounts_receivable) } }

    before { create(:customer_user).tap { |user| user.add_role(:accounts_receivable) } }

    it { is_expected.to(eq(staff_user)) }
  end
end
