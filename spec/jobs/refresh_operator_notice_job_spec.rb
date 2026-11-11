require 'rails_helper'

RSpec.describe(RefreshOperatorNoticeJob) do
  subject(:perform) { described_class.perform_now }

  let(:cache) { ActiveSupport::Cache::MemoryStore.new }
  let(:configured) { true }

  before do
    allow(OFREP).to(receive(:configured?).and_return(configured))
    allow(Rails).to(receive(:cache).and_return(cache))
    cache.write('operator_notice', 'status' => 'past_due')
  end

  context 'when not configured' do
    let(:configured) { false }

    before do
      allow(OFREP).to(receive(:evaluate))
      perform
    end

    it { expect(OFREP).not_to(have_received(:evaluate)) }
  end

  context 'when the flag changes' do
    before do
      allow(OFREP).to(receive(:evaluate).and_return('status' => 'suspended'))
      perform
    end

    it { expect(cache.read('operator_notice')).to(eq('status' => 'suspended')) }
  end

  context 'when the request fails' do
    before do
      allow(OFREP).to(receive(:evaluate).and_raise(OFREP::Error, 'timed out'))
      allow(Sentry).to(receive(:capture_exception))
      perform
    end

    it { expect(cache.read('operator_notice')).to(eq('status' => 'past_due')) }
    it { expect(Sentry).to(have_received(:capture_exception).with(instance_of(OFREP::Error))) }
  end
end
