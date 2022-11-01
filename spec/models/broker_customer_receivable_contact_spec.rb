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
require 'rails_helper'

RSpec.describe BrokerCustomerReceivableContact, type: :model do
  describe 'relationships' do
    it { is_expected.to belong_to(:broker_customer) }
    it { is_expected.to belong_to(:contact) }
  end
end
