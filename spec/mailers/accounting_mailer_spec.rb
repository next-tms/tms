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
      create(:setting, key: 'customer_service_email', value: 'help@acme.test')
      create(:setting, key: 'name', value: 'Acme Freight')
      create(:setting, key: 'robot_email', value: 'robot@acme.test')
    end

    it { expect(mail.from).to(eq(['robot@acme.test'])) }
    it { expect(mail[:from].to_s).to(eq('Acme Freight <robot@acme.test>')) }
    it { expect(mail.reply_to).to(eq(['help@acme.test'])) }
    it { expect(mail.subject).to(eq('Accounting Customer Sync Failure')) }
    it { expect(mail.to).to(eq([root_user.email])) }
  end
end
