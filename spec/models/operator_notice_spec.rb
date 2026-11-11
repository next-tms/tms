require 'rails_helper'

RSpec.describe(OperatorNotice) do
  subject(:operator_notice) { described_class.new(attributes) }

  let(:attributes) { { action_url: 'https://pay.example.com', message: 'Please call us', status: 'past_due' } }
  let(:cache) { ActiveSupport::Cache::MemoryStore.new }
  let(:configured) { true }

  before do
    allow(OFREP).to(receive(:configured?).and_return(configured))
    allow(Rails).to(receive(:cache).and_return(cache))
  end

  describe '.current' do
    subject(:current) { described_class.current }

    before { cache.write('operator_notice', 'message' => 'Please call us', 'status' => 'past_due', 'unknown' => 'ignored') }

    it { is_expected.to(be_past_due) }
    it { expect(current.message).to(eq('Please call us')) }

    context 'when not configured' do
      let(:configured) { false }

      it { expect(current.status).to(be_nil) }
    end

    context 'when nothing is cached' do
      before { cache.clear }

      it { expect(current.status).to(be_nil) }
    end
  end

  describe '.refresh!' do
    let(:value) { { 'status' => 'suspended' } }

    before do
      cache.write('operator_notice', 'status' => 'past_due')
      allow(OFREP).to(receive(:evaluate).with('operator_notice').and_return(value))
      described_class.refresh!
    end

    it { expect(cache.read('operator_notice')).to(eq('status' => 'suspended')) }

    context 'when the flag is missing' do
      let(:value) { nil }

      it { expect(cache.read('operator_notice')).to(be_nil) }
    end

    context 'when the value is not an object' do
      let(:value) { 'suspended' }

      it { expect(cache.read('operator_notice')).to(be_nil) }
    end
  end

  describe '#cache_key' do
    it { expect(operator_notice.cache_key).to(start_with('operator_notice/')) }
    it { expect(operator_notice.cache_key).to(eq(described_class.new(attributes).cache_key)) }
    it { expect(operator_notice.cache_key).not_to(eq(described_class.new(attributes.merge(status: 'suspended')).cache_key)) }
  end

  describe '#enforced?' do
    it { is_expected.not_to(be_enforced) }

    context 'when active after the enforcement time' do
      let(:attributes) { { enforce_at: 1.day.ago, status: 'active' } }

      it { is_expected.not_to(be_enforced) }
    end

    context 'when past due after the enforcement time' do
      let(:attributes) { { enforce_at: 1.minute.ago, status: 'past_due' } }

      it { is_expected.to(be_enforced) }
    end

    context 'when past due before the enforcement time' do
      let(:attributes) { { enforce_at: 1.day.from_now, status: 'past_due' } }

      it { is_expected.not_to(be_enforced) }
    end

    context 'when suspended' do
      let(:attributes) { { status: 'suspended' } }

      it { is_expected.to(be_enforced) }
    end
  end

  describe '#link_url' do
    it { expect(operator_notice.link_url).to(eq('https://pay.example.com')) }

    context 'with a javascript URL' do
      let(:attributes) { { action_url: 'javascript:alert(1)' } }

      it { expect(operator_notice.link_url).to(be_nil) }
    end

    context 'without an action URL' do
      let(:attributes) { {} }

      it { expect(operator_notice.link_url).to(be_nil) }
    end
  end

  describe '#past_due?' do
    it { is_expected.to(be_past_due) }

    context 'when suspended' do
      let(:attributes) { { status: 'suspended' } }

      it { is_expected.not_to(be_past_due) }
    end
  end

  describe '#suspended?' do
    it { is_expected.not_to(be_suspended) }

    context 'when suspended' do
      let(:attributes) { { status: 'suspended' } }

      it { is_expected.to(be_suspended) }
    end
  end

  describe '#visible_to?' do
    let(:broker_user) { create(:broker_user).tap { |user| user.add_role(:accounting) } }

    it { expect(operator_notice.visible_to?(broker_user)).to(be(true)) }
    it { expect(operator_notice.visible_to?(create(:broker_user).tap { |user| user.add_role(:dispatch) })).to(be(false)) }
    it { expect(operator_notice.visible_to?(build(:carrier_user))).to(be(false)) }
    it { expect(operator_notice.visible_to?(create(:customer_user).tap { |user| user.add_role(:accounting) })).to(be(false)) }
    it { expect(operator_notice.visible_to?(create(:root_broker_user))).to(be(true)) }
    it { expect(operator_notice.visible_to?(build(:customer_user))).to(be(false)) }
    it { is_expected.not_to(be_visible_to(nil)) }

    context 'when active' do
      let(:attributes) { { message: 'All good', status: 'active' } }

      it { expect(operator_notice.visible_to?(broker_user)).to(be(false)) }
    end

    context 'when enforced' do
      let(:attributes) { { enforce_at: 1.minute.ago, message: 'Please call us', status: 'past_due' } }

      it { expect(operator_notice.visible_to?(broker_user)).to(be(false)) }
    end

    context 'when suspended' do
      let(:attributes) { { message: 'Please call us', status: 'suspended' } }

      it { expect(operator_notice.visible_to?(broker_user)).to(be(false)) }
    end

    context 'without a message' do
      let(:attributes) { { status: 'past_due' } }

      it { expect(operator_notice.visible_to?(broker_user)).to(be(false)) }
    end
  end
end
