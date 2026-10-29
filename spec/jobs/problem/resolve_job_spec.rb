require 'rails_helper'

RSpec.describe(Problem::ResolveJob) do
  describe '#perform' do
    let(:problem) { build(:problem) }

    before do
      allow(problem).to(receive(:resolve))
      described_class.perform_now(problem)
    end

    it { expect(problem).to(have_received(:resolve)) }
  end
end
