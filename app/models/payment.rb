# frozen_string_literal: true

class Payment < ApplicationRecord
  scope :unpaid, -> { where(paid_on: nil) }
  scope :paid, -> { where.not(paid_on: nil) }

  belongs_to :approved_by, class_name: 'User', optional: true
  belongs_to :created_by, class_name: 'User', optional: true

  belongs_to :broker
  belongs_to :broker_carrier

  belongs_to :created_by, class_name: 'User'
  validates_presence_of :created_by

  has_many :payment_transactions, dependent: :delete_all
  accepts_nested_attributes_for :payment_transactions, allow_destroy: true, reject_if: :all_blank

  before_save :set_paid
  monetize :paid_cents

  def balance
    payment_transactions.map(&:balance).inject(Money.new(0)) { |sum, paid| sum += paid }
  end

  def has_invoice_numbers?
    unless (payment_transactions.map(&:invoice).uniq == [nil]) || (payment_transactions.map(&:invoice).uniq == [''])
      true
    end
  end

  private

  def set_paid
    self.paid = payment_transactions.map(&:paid).inject(Money.new(0)) { |sum, paid| sum += paid }
  end
end
