require 'rails_helper'

RSpec.describe(AccountingMailer) do
  describe('._helpers') do
    subject { described_class._helpers }

    it { is_expected.to(include(ApplicationHelper)) }
    it { is_expected.to(include(DateTimeHelper)) }
  end

  describe '#unknown_customers' do
    subject(:mail) { described_class.unknown_customers(broker_customers: BrokerCustomer.all) }

    let!(:root_user) { create(:root_broker_user) }

    before do
      create(:broker_customer)
      create(:customer_user).tap { |user| user.contact.contact_roles.create!(role: :root) }
    end

    it { expect(mail.to).to(eq([ root_user.email ])) }
  end
end
