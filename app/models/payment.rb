# frozen_string_literal: true

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
# @!attribute week
#   @return [Integer]
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
  scope :unpaid, -> { where(paid_on: nil) }
  scope :paid, -> { where.not(paid_on: nil) }

  before_save :set_due_on
  before_save :set_paid
  before_save :set_week

  belongs_to :approved_by, class_name: 'User', optional: true
  belongs_to :created_by, class_name: 'User', optional: true

  belongs_to :bank, optional: true
  belongs_to :broker
  belongs_to :broker_carrier
  belongs_to :payment_method, optional: true

  belongs_to :created_by, class_name: 'User'
  validates_presence_of :created_by

  has_many :payment_transactions, dependent: :destroy
  accepts_nested_attributes_for :payment_transactions, allow_destroy: true, reject_if: :all_blank

  monetize :paid_cents

  def export_headers
    ['Account', 'Date', 'Description', 'Amount']
  end

  def to_csv(with_headers)
    return '' if paid_cents.blank? || paid_cents == 0

    columns = ['Account', 'Description', 'Amount']
    CSV.generate do |csv|
      csv << export_headers if with_headers

      csv << [
        "#{bank&.name} #{bank&.account_number}".upcase.squish,
        paid_on&.strftime('%m-%d-%Y'),
        "#{payment_method&.name} #{method_reference} TO #{broker_carrier&.carrier&.name}".upcase.squish,
        "-#{paid_cents.to_f / 100}"
      ]
    end
  end

  def balance
    payment_transactions.map(&:balance).inject(Money.new(0)) { |sum, paid| sum += paid }
  end

  def has_invoice_numbers?
    unless (payment_transactions.map(&:invoice).uniq == [nil]) || (payment_transactions.map(&:invoice).uniq == [''])
      true
    end
  end

  private

  def set_due_on
    return if payment_transactions.blank?
    date = (payment_transactions.map(&:due_on).uniq - [nil]).sort.first
    due_on = date
  end

  def set_paid
    self.paid = payment_transactions.map(&:paid).inject(Money.new(0)) { |sum, paid| sum += paid }
  end

  def set_week
    return if payment_transactions.blank?
    week = (payment_transactions.map(&:week).uniq - [nil]).sort.first
  end
end
