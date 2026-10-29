require 'rails_helper'

RSpec.describe(ProblematicService::Action::Shipment) do
  describe '#shipment' do
    let(:problem) { build(:problem) }

    it { expect(described_class.new(problem).shipment).to(eq(problem.resolvable)) }
  end
end
