require 'rails_helper'

RSpec.describe(ProblematicService::Action) do
  let(:problem) { build(:problem) }

  describe '.call' do
    let(:action) { instance_double(described_class, call: true) }

    before do
      allow(described_class).to(receive(:new).with(problem).and_return(action))
      described_class.call(problem)
    end

    it { expect(action).to(have_received(:call)) }
  end

  describe '#call' do
    it { expect { described_class.new(problem).call }.to(raise_error(NotImplementedError)) }
  end

  describe '#discussion_topic' do
    let(:discussion_topic) { DiscussionTopic.new }

    before { allow(problem).to(receive(:discussion_topic).and_return(discussion_topic)) }

    it { expect(described_class.new(problem).discussion_topic).to(eq(discussion_topic)) }
  end

  describe '#discussion_topic?' do
    it { expect(described_class.new(problem).discussion_topic?).to(be(false)) }

    context 'when problem has a discussion topic' do
      before { allow(problem).to(receive(:discussion_topic).and_return(DiscussionTopic.new)) }

      it { expect(described_class.new(problem).discussion_topic?).to(be(true)) }
    end
  end
end
