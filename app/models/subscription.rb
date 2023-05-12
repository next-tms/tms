# frozen_string_literal: true

# == Schema Information
#
# Table name: subscriptions
#
# @!attribute id
#   @return []
# @!attribute canceled_at
#   @return [Time]
# @!attribute record_type
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute contact_id
#   @return []
# @!attribute record_id
#   @return []
#
# Indexes
#
#  index_subscriptions_on_canceled_at                               (canceled_at)
#  index_subscriptions_on_contact_id                                (contact_id)
#  index_subscriptions_on_contact_id_and_record_id_and_record_type  (contact_id,record_id,record_type) UNIQUE
#  index_subscriptions_on_record                                    (record_type,record_id)
#
# Foreign Keys
#
#  fk_rails_...  (contact_id => contacts.id)
#
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
