require 'rails_helper'

RSpec.describe(ProblematicService::Processor::Shipment) do
  describe '.call' do
    subject(:call) { described_class.call(shipment) }

    let(:shipment) { create(:shipment, delivered_at: nil, lost_on: nil, picked_up_at: nil).tap { |shipment| shipment.problems.delete_all } }

    it { expect { call }.to(change { shipment.problems.unresolved.pluck(:problematic_rule_code) }.from([]).to(%w[missing_picked_up_at])) }
  end
end
