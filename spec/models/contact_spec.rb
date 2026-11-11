require 'rails_helper'

RSpec.describe(Contact) do
  describe 'relationships' do
    it { is_expected.to(have_many(:contact_roles)) }
    it { is_expected.to(have_many(:document_preferences)) }
  end

  describe '#role?' do
    let(:broker_customer) { create(:broker_customer) }
    let(:record) { create(:contact, companyable: broker_customer) }

    it { expect(record.role?(:customer)).to(be(true)) }
    it { expect(record.role?(:accounts_payable)).to(be(false)) }

    context 'when record is the receivables contact of its BrokerCustomer' do
      before { allow(broker_customer).to(receive(:receivables_contact).and_return(record)) }

      it { expect(record.role?('accounts_payable')).to(be(true)) }
    end
  end

  describe 'unique email index' do
    before { create(:contact, companyable: nil, email: 'staff@acme.test') }

    it { expect { build(:contact, companyable: nil, email: 'staff@acme.test').save(validate: false) }.to(raise_error(ActiveRecord::RecordNotUnique)) }

    it do
      expect { build_list(:contact, 2, companyable: nil, email: nil).each { |contact| contact.save!(validate: false) } }.not_to(raise_error)
    end
  end
end
