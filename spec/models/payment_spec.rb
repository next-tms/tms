require 'rails_helper'

RSpec.describe(Payment) do
  describe '#overdue?' do
    let(:due_on) { 2.days.ago.to_date }
    let(:record) { described_class.new(due_on:) }

    before { create(:setting, key: 'time_zone_name', value: 'America/Los_Angeles') }

    it { expect(record).to(be_overdue) }

    context 'when due_on is in the future' do
      let(:due_on) { 2.days.from_now.to_date }

      it { expect(record).not_to(be_overdue) }
    end

    context 'when paid' do
      before { record.paid_on = Date.current }

      it { expect(record).not_to(be_overdue) }
    end
  end
end
