require 'rails_helper'

RSpec.describe(ProblematicService::Action::Shipment::MissingPickedUpAt) do
  describe '#call' do
    subject(:call) { described_class.new(problem).call }

    let(:problem) { create(:problem, problematic_rule_code: 'missing_picked_up_at', resolvable: shipment) }
    let(:shipment) { create(:shipment, created_at: 2.weeks.ago, dispatched_at: nil, picked_up_at: nil) }

    context 'when the shipment was created within one week' do
      let(:shipment) { create(:shipment, dispatched_at: nil, picked_up_at: nil) }

      it { is_expected.to(be(false)) }
    end

    context 'when the shipment is not booked' do
      before { shipment.update_columns(booked_at: nil) }

      it { expect { call }.to(change { shipment.reload.canceled_at }.from(nil)) }
      it { expect { call }.to(change { problem.discussion_topic.comments.pluck(:body) }.to([ described_class::COMMENTS[:cancel] ])) }
    end

    context 'when the shipment was booked within one week' do
      before { shipment.update_columns(booked_at: 2.days.ago) }

      it { is_expected.to(be(false)) }
    end

    context 'when the shipment was booked over one week ago' do
      before { shipment.update_columns(booked_at: 2.weeks.ago) }

      it { expect { call }.to(change { shipment.reload.booked_at }.to(nil)) }
      it { expect { call }.to(change { problem.discussion_topic.comments.pluck(:body) }.to([ described_class::COMMENTS[:unbook] ])) }
    end
  end
end
