# == Schema Information
#
# Table name: broker_customer_receivable_contacts
#
# @!attribute id
#   @return []
# @!attribute primary
#   @return [Boolean]
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute broker_customer_id
#   @return []
# @!attribute contact_id
#   @return []
#
# Indexes
#
#  index_broker_customer_receivable_contacts_on_broker_customer_id  (broker_customer_id)
#  index_broker_customer_receivable_contacts_on_contact_id          (contact_id)
#
# Foreign Keys
#
#  fk_rails_...  (broker_customer_id => broker_customers.id)
#  fk_rails_...  (contact_id => contacts.id)
#
class BrokerCustomerReceivableContact < ApplicationRecord
  belongs_to :broker_customer
  belongs_to :contact

  validates :contact, uniqueness: { scope: :broker_customer }
  validate :ensure_one_primary_contact
  validate :check_if_contact_exists

  accepts_nested_attributes_for :contact

  def ensure_one_primary_contact
    return if primary
    return if self.broker_customer.broker_customer_receivable_contacts.where(primary: true).present?

    errors.add(:base, "Requires atleast 1 primary receivable contact")
  end

  def check_if_contact_exists
    return if contact.persisted?

    existing_contact = broker_customer.contacts.find_by(email: contact.email)
    self.contact = existing_contact if existing_contact
  end
end
