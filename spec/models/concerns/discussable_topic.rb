require 'rails_helper'
require 'spec_helper'

shared_examples_for 'discussable_topic' do
  let(:record) { build(described_class.name.underscore.to_sym) }

  describe 'relationships' do
    it { expect(record).to(have_many(:comments).through(:discussion_topic)) }
    it { expect(record).to(have_one(:discussion_topic).dependent(:destroy)) }
  end

  describe 'included methods' do
    # @note `delegate`, `has_one` both fail in `before_save` callback so it should be a method
    it { expect(record).to(respond_to(:discussion)) }

    it { expect(record).to(respond_to(:build_discussable_topic?)) }
    it { expect(record).to(respond_to(:discussable_topic_description)) }
    it { expect(record).to(respond_to(:discussable?)) }
    it { expect(record).to(respond_to(:eligible_discussable_contacts)) }
  end

  describe '#build_discussable_topic' do
    context 'when not discussion.present?' do
      before do
        allow(record).to(receive_messages(build_discussable_topic?: true, discussion: nil))
      end

      it "doesn't set #discussion" do
        record.__send__(:build_discussion_topic)
        expect(record.discussion_topic).to(be_nil)
      end
    end

    context 'when not build_discussable_topic?' do
      before do
        allow(record).to(receive(:build_discussable_topic?).and_return(false))
        record.resolvable.build_discussion if described_class == Problem
      end

      it "doesn't set #discussion" do
        record.__send__(:build_discussion_topic)
        expect(record.discussion_topic).to(be_nil)
      end
    end

    context 'when discussion.present? && build_discussable_topic?' do
      before do
        allow(record).to(receive(:build_discussable_topic?).and_return(true))
        record.resolvable.build_discussion if described_class == Problem
      end

      it { expect(record.__send__(:build_discussion_topic)).to(be_a(DiscussionTopic)) }

      it 'sets #discussion' do
        record.__send__(:build_discussion_topic)
        expect(record.discussion_topic).to(be_present)
      end
    end
  end
end
