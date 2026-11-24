require 'rails_helper'

RSpec.describe(Receivable) do
  it_behaves_like 'discussable'

  describe '.ransackable_attributes' do
    it { expect(described_class.ransackable_attributes(build(:customer_user))).to(include(*described_class::CHARGE_COLUMNS)) }
    it { expect(described_class.ransackable_attributes(build(:carrier_user))).not_to(include('total_cents')) }
    it { expect(described_class.ransackable_attributes).not_to(include('total_cents')) }
  end

  describe '#missing_carrier_bol?' do
    let(:broker_customer) { create(:broker_customer) }
    let(:shipment) { create(:shipment, broker_customer:) }
    let(:record) { build(:receivable, shipment:) }

    let(:result) { record.missing_carrier_bol? }

    it { expect { result }.not_to(raise_error) }

    context 'when broker_customer.blank?' do
      let(:shipment) { create(:shipment, broker_customer: nil) }

      it { expect(result).to(be(false)) }
    end

    context 'when broker_customer.requires_carrier_bol_on_receivables?' do
      let(:broker_customer) { create(:broker_customer, requires_carrier_bol_on_receivables: true) }

      it { expect(result).to(be(true)) }
    end

    context 'when not broker_customer.requires_carrier_bol_on_receivables?' do
      let(:broker_customer) { create(:broker_customer, requires_carrier_bol_on_receivables: false) }

      it { expect(result).to(be(false)) }
    end
  end

  describe '#missing_carrier_pod?' do
    let(:broker_customer) { create(:broker_customer) }
    let(:shipment) { create(:shipment, broker_customer:) }
    let(:record) { build(:receivable, shipment:) }

    let(:result) { record.missing_carrier_pod? }

    it { expect { result }.not_to(raise_error) }

    context 'when broker_customer.blank?' do
      let(:shipment) { create(:shipment, broker_customer: nil) }

      it { expect(result).to(be(false)) }
    end

    context 'when broker_customer.requires_carrier_pod_on_receivables?' do
      let(:broker_customer) { create(:broker_customer, requires_carrier_pod_on_receivables: true) }

      it { expect(result).to(be(true)) }
    end

    context 'when not broker_customer.requires_carrier_pod_on_receivables?' do
      let(:broker_customer) { create(:broker_customer, requires_carrier_pod_on_receivables: false) }

      it { expect(result).to(be(false)) }
    end
  end

  describe '#save' do
    let(:error) { Accounting::QuickBooks::Service::Disconnected.new }
    let(:record) { build(:receivable, authorized_at: nil) }

    before do
      allow(Accounting).to(receive(:connected?).and_return(true))
      allow(record).to(receive(:accounting_invoice).and_raise(error))
      allow(Sentry).to(receive(:capture_exception))
    end

    it { expect(record.save).to(be(true)) }

    it 'leaves the receivable unauthorized and uninvoiced' do
      record.save

      expect(record.reload).to(have_attributes(authorized_at: nil, invoiced: false))
    end

    it 'reports the accounting error' do
      record.save

      expect(Sentry).to(have_received(:capture_exception).with(error).twice)
    end
  end

  describe '#sendable?' do
    let(:broker_customer) do
      create(:broker_customer, requires_carrier_bol_on_receivables: false, requires_carrier_pod_on_receivables: false)
    end
    let(:error) { Accounting::QuickBooks::Service::Disconnected.new }
    let(:record) { create(:receivable, shipment:) }
    let(:shipment) { create(:shipment, broker_customer:, picked_up_at: Time.current) }

    let(:result) { record.sendable? }

    before do
      allow(record).to(receive_messages(balance_cents: 100, update_from_api: nil))
      allow(record).to(receive(:fetch_invoice).and_raise(error))
      allow(Sentry).to(receive(:capture_exception))
    end

    it { expect(result).to(be(false)) }

    it 'reports the accounting error' do
      result

      expect(Sentry).to(have_received(:capture_exception).with(error))
    end
  end

  describe '#update_from_api' do
    let(:broker_customer) do
      create(:broker_customer, requires_carrier_bol_on_receivables: false, requires_carrier_pod_on_receivables: false)
    end
    let(:error) { OAuth2::Error.new({ 'error' => 'invalid_grant' }) }
    let(:record) { create(:receivable, shipment: create(:shipment, broker_customer:)) }

    let(:result) { record.update_from_api }

    before do
      allow(Accounting).to(receive(:connected?).and_return(true))
      allow(record).to(receive(:update_from_accounting_invoice).and_raise(error))
      allow(Sentry).to(receive(:capture_exception))
    end

    it { expect { result }.not_to(raise_error) }

    it 'reports the accounting error' do
      result

      expect(Sentry).to(have_received(:capture_exception).with(error))
    end
  end

  describe 'validations' do
    subject { record }

    let(:broker_customer) do
      create(:broker_customer, requires_carrier_bol_on_receivables: false, requires_carrier_pod_on_receivables: false)
    end
    let(:shipment) { create(:shipment, broker_customer:) }

    before do
      record
      broker_customer.update!(requires_carrier_bol_on_receivables: true)
      create(:problem, problematic_rule_code: 'missing_carrier_bol', resolvable: shipment)
    end

    context 'when the receivable exists' do
      let(:record) { create(:receivable, shipment:) }

      it { is_expected.to(be_valid) }
    end

    context 'when the receivable is new' do
      let(:record) { build(:receivable, shipment:) }

      it { is_expected.not_to(be_valid) }
    end
  end
end
