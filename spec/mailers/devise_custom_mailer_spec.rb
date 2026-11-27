require 'rails_helper'

RSpec.describe(DeviseCustomMailer) do
  describe '#invitation_instructions' do
    subject(:mail) { described_class.invitation_instructions(user, 'token') }

    let(:user) { create(:customer_user) }

    before { create(:setting, key: 'robot_email', value: 'robot@acme.test') }

    it { expect(mail.from).to(eq(['robot@acme.test'])) }
    it { expect(mail.reply_to).to(eq(['robot@acme.test'])) }
  end

  describe '#reset_password_instructions' do
    subject(:mail) { described_class.reset_password_instructions(user, 'token') }

    let(:user) { create(:customer_user) }

    before do
      create(:setting, key: 'name', value: 'Acme Freight')
      create(:setting, key: 'robot_email', value: 'robot@acme.test')
    end

    it { expect(mail[:from].to_s).to(eq('Acme Freight <robot@acme.test>')) }
  end
end
