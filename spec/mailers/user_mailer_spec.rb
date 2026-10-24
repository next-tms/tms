require 'rails_helper'

RSpec.describe(UserMailer) do
  describe('._helpers') do
    subject { described_class._helpers }

    it { is_expected.to(include(ApplicationHelper)) }
    it { is_expected.to(include(DateTimeHelper)) }
  end

  describe '#send_welcome' do
    subject(:mail) { described_class.send_welcome(user) }

    let(:user) { create(:customer_user) }

    before do
      create(:setting, key: 'customer_service_email', value: 'help@acme.test')
      create(:setting, key: 'name', value: 'Acme Freight')
      create(:setting, key: 'robot_email', value: 'robot@acme.test')
    end

    it { expect(mail.from).to(eq([ 'robot@acme.test' ])) }
    it { expect(mail.reply_to).to(eq([ 'help@acme.test' ])) }
    it { expect(mail.subject).to(eq('Welcome to Acme Freight')) }
    it { expect(mail.body.encoded).to(include('Welcome to Acme Freight.')) }
  end
end
