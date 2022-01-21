# frozen_string_literal: true

# == Schema Information
#
# Table name: document_preferences
#
# @!attribute id
#   @return []
# @!attribute kind
#   @return [String]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute broker_customer_id
#   @return []
# @!attribute broker_id
#   @return []
# @!attribute contact_id
#   @return []
#
# Indexes
#
#  index_document_preferences_on_broker_customer_id  (broker_customer_id)
#  index_document_preferences_on_broker_id           (broker_id)
#  index_document_preferences_on_contact_id          (contact_id)
#  index_document_preferences_on_kind                (kind)
#
# Foreign Keys
#
#  fk_rails_...  (broker_customer_id => broker_customers.id)
#  fk_rails_...  (broker_id => brokers.id)
#  fk_rails_...  (contact_id => contacts.id)
#
class DocumentPreference < ApplicationRecord
  before_validation :set_broker

  belongs_to :broker
  belongs_to :broker_customer, optional: true
  belongs_to :contact

  enum kind: { carrier_bol: 'carrier_bol', carrier_pod: 'carrier_pod' }

  validates :kind, presence: true

  private

  def set_broker
    self.broker = broker_customer&.broker if self.broker.blank?
  end
end
