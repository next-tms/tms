# @deprecated Moved to BrokerCustomer#receivables_contact
class BrokerCustomerReceivableContact < ApplicationRecord
  belongs_to :broker_customer
  belongs_to :contact

  validates :contact, uniqueness: { scope: :broker_customer }
  validate :ensure_one_primary_contact
  validate :check_if_contact_exists

  accepts_nested_attributes_for :contact

  def ensure_one_primary_contact
    return if primary
    return if broker_customer.broker_customer_receivable_contacts.where(primary: true).present?

    errors.add(:base, 'Requires atleast 1 primary receivable contact')
  end

  def check_if_contact_exists
    return if contact.persisted?

    existing_contact = broker_customer.contacts.find_by(email: contact.email)
    self.contact = existing_contact if existing_contact
  end
end
