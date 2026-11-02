require 'rails_helper'

RSpec.describe(APIKeyMailer) do
  describe '#expiring' do
    subject(:mail) { described_class.with(api_key:).expiring }

    let(:api_key) { create(:api_key, name: 'Warehouse WMS') }

    before do
      create(:setting, key: 'name', value: 'Next TMS')
      create(:setting, key: 'robot_email', value: 'robot@example.com')
    end

    it { expect(mail.to).to(eq([api_key.authorizable.email])) }
    it { expect(mail.subject).to(include('Warehouse WMS')) }
    it { expect(mail.body.encoded).to(include("/account/api-keys/#{api_key.id}")) }
  end
end
