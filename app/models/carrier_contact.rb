# frozen_string_literal: true

# == Schema Information
#
# Table name: carrier_contacts
#
# @!attribute id
#   @return []
# @!attribute broker_id
#   @return []
# @!attribute carrier_id
#   @return []
# @!attribute contact_id
#   @return []
#
# Indexes
#
#  index_carrier_contacts_on_broker_id   (broker_id)
#  index_carrier_contacts_on_carrier_id  (carrier_id)
#  index_carrier_contacts_on_contact_id  (contact_id)
#
# Foreign Keys
#
#  fk_rails_...  (broker_id => brokers.id)
#  fk_rails_...  (carrier_id => carriers.id)
#  fk_rails_...  (contact_id => contacts.id)
#
class CarrierContact < ApplicationRecord
  belongs_to :broker
  validates :broker, presence: true

  belongs_to :carrier
  validates :carrier, presence: true

  belongs_to :contact
  validates :contact, presence: true

  accepts_nested_attributes_for :contact
end
