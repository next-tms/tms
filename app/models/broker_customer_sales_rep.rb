class BrokerCustomerSalesRep < ApplicationRecord
  belongs_to :broker_customer
  belongs_to :user

  has_many :shipments, through: :commissions

  monetize :commission_flat_cents

  validate :validate_commission_flat_cents_or_commission_percent

  private

  def validate_commission_flat_cents_or_commission_percent
    values = [commission_flat_cents, commission_percent]
    return unless values.all?(&:blank?) || values.compact_blank.all?(&:zero?)

    errors.add(:commission_percent, "or #{self.class.human_attribute_name(:commission_flat).downcase} must be non-zero")
  end
end
