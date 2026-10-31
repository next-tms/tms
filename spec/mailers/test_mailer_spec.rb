require 'rails_helper'

RSpec.describe(TestMailer) do
  describe '#hello' do
    subject(:mail) { described_class.hello }

    it { expect(mail.subject).to(eq('Hello from Next TMS')) }
  end
end
