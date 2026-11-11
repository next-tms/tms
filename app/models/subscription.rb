class Subscription < ApplicationRecord
  belongs_to :contact
  belongs_to :record, polymorphic: true

  has_one :user, through: :contact

  scope :active, -> { where(canceled_at: nil) }
  scope :canceled, -> { where.not(canceled_at: nil) }

  validates :contact_id, uniqueness: { scope: %i[record_id record_type] }

  def active!
    update!(canceled_at: nil)
  end

  def cancel!
    update!(canceled_at: Time.current)
  end

  def canceled?
    canceled_at.present?
  end
end
