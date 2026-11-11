# == Schema Information
#
# Table name: payments
#
# @!attribute id
#   @return []
# @!attribute approved_at
#   @return [Time]
# @!attribute due_on
#   @return [Date]
# @!attribute method
#   @return [String]
# @!attribute method_reference
#   @return [String]
# @!attribute paid_cents
#   @return [Integer]
# @!attribute paid_currency
#   @return [String]
# @!attribute paid_on
#   @return [Date]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute accounting_bill_payment_id
#   @return [Integer]
# @!attribute approved_by_id
#   @return []
# @!attribute bank_id
#   @return []
# @!attribute broker_carrier_id
#   @return []
# @!attribute created_by_id
#   @return []
# @!attribute payment_method_id
#   @return []
#
# Indexes
#
#  index_payments_on_approved_by_id     (approved_by_id)
#  index_payments_on_bank_id            (bank_id)
#  index_payments_on_broker_carrier_id  (broker_carrier_id)
#  index_payments_on_created_by_id      (created_by_id)
#  index_payments_on_payment_method_id  (payment_method_id)
#
# Foreign Keys
#
#  fk_rails_...  (approved_by_id => users.id)
#  fk_rails_...  (bank_id => banks.id)
#  fk_rails_...  (broker_carrier_id => broker_carriers.id)
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (payment_method_id => payment_methods.id)
#
# @!attribute id
#   @return []
# @!attribute approved_at
#   @return [Time]
# @!attribute due_on
#   @return [Date]
# @!attribute method
#   @return [String]
# @!attribute method_reference
#   @return [String]
# @!attribute paid_cents
#   @return [Integer]
# @!attribute paid_currency
#   @return [String]
# @!attribute paid_on
#   @return [Date]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute accounting_bill_payment_id
#   @return [Integer]
# @!attribute approved_by_id
#   @return []
# @!attribute bank_id
#   @return []
# @!attribute broker_carrier_id
#   @return []
# @!attribute created_by_id
#   @return []
# @!attribute payment_method_id
#   @return []
#
# Indexes
#
#  index_payments_on_approved_by_id     (approved_by_id)
#  index_payments_on_bank_id            (bank_id)
#  index_payments_on_broker_carrier_id  (broker_carrier_id)
#  index_payments_on_created_by_id      (created_by_id)
#  index_payments_on_payment_method_id  (payment_method_id)
#
# Foreign Keys
#
#  fk_rails_...  (approved_by_id => users.id)
#  fk_rails_...  (bank_id => banks.id)
#  fk_rails_...  (broker_carrier_id => broker_carriers.id)
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (payment_method_id => payment_methods.id)
#
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
