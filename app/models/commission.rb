# frozen_string_literal: true

# == Schema Information
#
# Table name: commissions
#
# @!attribute id
#   @return []
# @!attribute amount_cents
#   @return [Integer]
# @!attribute amount_currency
#   @return [String]
# @!attribute paid
#   @return [Boolean]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute broker_customer_sales_rep_id
#   @return []
# @!attribute shipment_id
#   @return []
#
# Indexes
#
#  index_commissions_on_broker_customer_sales_rep_id  (broker_customer_sales_rep_id)
#  index_commissions_on_shipment_id                   (shipment_id)
#
# Foreign Keys
#
#  fk_rails_...  (broker_customer_sales_rep_id => broker_customer_sales_reps.id)
#  fk_rails_...  (shipment_id => shipments.id)
#
class Commission < ApplicationRecord
  belongs_to :broker_customer_sales_rep
  belongs_to :shipment

  monetize :amount_cents

  scope :paid, -> { where(paid: true) }
  scope :unpaid, -> { where.not(id: paid) }

  def percent
    (amount.to_f / shipment.profit.to_f).round(2)
  end
end
