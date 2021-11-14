# frozen_string_literal: true

# == Schema Information
#
# Table name: customer_contacts
#
# @!attribute id
#   @return []
# @!attribute broker_id
#   @return []
# @!attribute contact_id
#   @return []
# @!attribute customer_id
#   @return []
#
# Indexes
#
#  index_customer_contacts_on_broker_id    (broker_id)
#  index_customer_contacts_on_contact_id   (contact_id)
#  index_customer_contacts_on_customer_id  (customer_id)
#
# Foreign Keys
#
#  fk_rails_...  (broker_id => brokers.id)
#  fk_rails_...  (contact_id => contacts.id)
#  fk_rails_...  (customer_id => customers.id)
#
class CustomerContact < ApplicationRecord
  belongs_to :broker
  validates :broker, presence: true

  belongs_to :customer
  validates :customer, presence: true

  belongs_to :contact
  validates :contact, presence: true

  accepts_nested_attributes_for :contact
end
