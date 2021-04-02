# frozen_string_literal: true

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

  has_many :payment_transactions, dependent: :delete_all
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
        "#{bank&.name} #{bank&.account_number}".upcase.strip,
        paid_on&.to_s,
        "#{payment_method&.name} #{method_reference}".upcase.strip,
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
