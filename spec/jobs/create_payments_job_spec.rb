require 'rails_helper'

RSpec.describe(CreatePaymentsJob) do
  describe '#perform' do
    subject(:perform) { described_class.perform_now }

    let(:now) { Time.find_zone('America/Chicago').local(2026, 10, 25, 21, 30) }
    let!(:payment_transaction) { create(:payment_transaction, due_on: now.to_date) }

    before do
      create(:setting, key: 'time_zone_name', value: 'America/Chicago')
      allow(CreatePaymentJob).to(receive(:perform_later))
    end

    around { |example| Timecop.freeze(now) { example.run } }

    it { is_expected.to(be(true)) }

    it do
      perform
      expect(CreatePaymentJob).to(have_received(:perform_later).with(broker_carrier: payment_transaction.broker_carrier, payment_transaction_ids: [ payment_transaction.id ]))
    end

    context 'when it is not Sunday night in the time zone setting' do
      let(:now) { Time.find_zone('America/Chicago').local(2026, 10, 26, 21, 30) }

      it { is_expected.to(be(false)) }
    end
  end
end
