class Payment < ApplicationRecord
  class << self
    def ransackable_associations(_auth_object = nil)
      ['approved_by', 'bank', 'broker_carrier', 'payment_transactions']
    end
  end

  include Payment::Accounting

  audited

  belongs_to :approved_by, class_name: 'User', optional: true
  belongs_to :bank, optional: true
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
  ransacker(:id_text) { Arel.sql("CAST(\"#{table_name}\".\"id\" AS text)") }

  validates :due_on, presence: true

  def balance
    Money.new(payment_transactions.sum(:balance_cents))
  end

  def due?
    !paid?
  end

  def overdue?
    due? && due_on < Setting.time_zone.now.to_date
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
