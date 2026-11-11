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
FactoryBot.define do
  factory :payment do
    broker_carrier
    due_on { Date.current }
  end
end
