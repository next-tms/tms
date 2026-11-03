# == Schema Information
#
# Table name: receivables
#
# @!attribute id
#   @return []
# @!attribute authorized_at
#   @return [Time]
# @!attribute balance_cents
#   @return [Integer]
# @!attribute balance_currency
#   @return [String]
# @!attribute due_by
#   @return [Time]
# @!attribute invoiced
#   @return [Boolean]
# @!attribute paid_at
#   @return [Time]
# @!attribute sent_at
#   @return [Time]
# @!attribute total_cents
#   @return [Integer]
# @!attribute total_currency
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute accounting_invoice_id
#   @return [String]
# @!attribute authorized_by_id
#   @return []
# @!attribute created_by_id
#   @return []
# @!attribute sent_by_id
#   @return []
# @!attribute shipment_id
#   @return []
# @!attribute updated_by_id
#   @return []
#
# Indexes
#
#  index_receivables_on_authorized_at     (authorized_at)
#  index_receivables_on_authorized_by_id  (authorized_by_id)
#  index_receivables_on_created_by_id     (created_by_id)
#  index_receivables_on_due_by            (due_by)
#  index_receivables_on_invoiced          (invoiced)
#  index_receivables_on_paid_at           (paid_at)
#  index_receivables_on_sent_by_id        (sent_by_id)
#  index_receivables_on_shipment_id       (shipment_id) UNIQUE
#  index_receivables_on_updated_by_id     (updated_by_id)
#
# Foreign Keys
#
#  fk_rails_...  (authorized_by_id => users.id)
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (sent_by_id => users.id)
#  fk_rails_...  (shipment_id => shipments.id)
#  fk_rails_...  (updated_by_id => users.id)
#
require 'rails_helper'

RSpec.describe(Receivable) do
  it_behaves_like 'discussable'

  describe '.ransackable_attributes' do
    it { expect(described_class.ransackable_attributes(build(:customer_user))).to(include(*described_class::CHARGE_COLUMNS)) }
    it { expect(described_class.ransackable_attributes(build(:user, companyable: build(:broker_carrier)))).not_to(include('total_cents')) }
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
end
