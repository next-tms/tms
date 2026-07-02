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
# @!attribute approved_by_id
#   @return []
# @!attribute bank_id
#   @return []
# @!attribute broker_carrier_id
#   @return []
# @!attribute broker_id
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
#  fk_rails_...  (broker_id => brokers.id)
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (payment_method_id => payment_methods.id)
#
class Payment < ApplicationRecord
  class << self
    def ransackable_attributes(auth_object = nil)
      [ 'due_on', 'id', 'paid_cents' ]
    end

    def ransackable_associations(auth_object = nil)
      [ 'approved_by', 'bank', 'broker_carrier', 'payment_transactions' ]
    end
  end

  include Payment::Accounting

  audited

  belongs_to :approved_by, class_name: 'User', optional: true
  belongs_to :bank, optional: true
  belongs_to :broker
  belongs_to :broker_carrier
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :payment_method, optional: true

  has_many :payment_transactions, dependent: :nullify
  accepts_nested_attributes_for :payment_transactions, allow_destroy: true, reject_if: :all_blank

  has_many :shipments, through: :payment_transactions

  monetize :paid_cents

  scope :approved, -> { where(approved_by: nil) }
  scope :due, -> { where(paid_on: nil) }
  scope :paid, -> { where.not(paid_on: nil) }
  scope :unapproved, -> { where.not(approved_by: nil) }

  # https://github.com/activerecord-hackery/ransack/issues/224#issuecomment-22818039
  ransacker :id do
    Arel.sql("to_char(\"#{table_name}\".\"id\", '99999999')")
  end

  validates :due_on, presence: true

  def balance
    Money.new(payment_transactions.sum(:balance_cents))
  end

  def due?
    !paid?
  end

  def overdue?
    due? && due_on < broker.time_zone.now.to_date
  end

  def paid
    payment_transactions.sum(&:paid)
  end

  def paid?
    paid_on.present?
  end

  def shipment_carrier_costs
    Money.new(shipments.sum(:carrier_cost_cents))
  end

  def variance
    balance - paid
  end
end
