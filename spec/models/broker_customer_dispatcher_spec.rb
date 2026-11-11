require 'rails_helper'

RSpec.describe(BrokerCustomerDispatcher) do
  describe 'relationships' do
    it { is_expected.to(belong_to(:broker_customer)) }
    it { is_expected.to(belong_to(:user)) }
  end
end
