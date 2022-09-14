# == Schema Information
#
# Table name: broker_customer_dispatchers
#
# @!attribute id
#   @return []
# @!attribute created_at
#   @return [Time]
# @!attribute updated_at
#   @return [Time]
# @!attribute broker_customer_id
#   @return []
# @!attribute user_id
#   @return []
#
# Indexes
#
#  index_broker_customer_dispatchers_on_broker_customer_id  (broker_customer_id)
#  index_broker_customer_dispatchers_on_user_id             (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (broker_customer_id => broker_customers.id)
#  fk_rails_...  (user_id => users.id)
#
require 'rails_helper'

RSpec.describe BrokerCustomerDispatcher, type: :model do
  describe 'relationships' do
    it { is_expected.to belong_to(:broker_customer) }
    it { is_expected.to belong_to(:user) }
  end
end
