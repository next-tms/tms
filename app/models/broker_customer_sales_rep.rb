# frozen_string_literal: true

# == Schema Information
#
# Table name: broker_customer_sales_reps
#
# @!attribute id
#   @return []
# @!attribute commission_flat_cents
#   @return [Integer]
# @!attribute commission_flat_currency
#   @return [String]
# @!attribute commission_percent
#   @return []
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute broker_customer_id
#   @return []
# @!attribute user_id
#   @return []
#
# Indexes
#
#  index_broker_customer_sales_reps_on_broker_customer_id  (broker_customer_id)
#  index_broker_customer_sales_reps_on_user_id             (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (broker_customer_id => broker_customers.id)
#  fk_rails_...  (user_id => users.id)
#
class BrokerCustomerSalesRep < ApplicationRecord
  belongs_to :broker_customer
  belongs_to :user

  has_many :shipments, through: :commissions

  monetize :commission_flat_cents

  validate :commission_flat_cents_or_commission_percent

  private

  def commission_flat_cents_or_commission_percent
    return unless [commission_flat_cents, commission_percent].all?(&:zero?)

    errors.add(:commission_percent, "or #{self.class.human_attribute_name(:commission_flat).downcase} must be non-zero")
  end
end
