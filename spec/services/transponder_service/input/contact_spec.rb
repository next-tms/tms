require 'rails_helper'

RSpec.describe(TransponderService::Input::Contact) do
  describe '#build' do
    context 'when object is a Setting' do
      subject(:result) { described_class.new(Setting.find_by!(key: 'mailing_address')).build }

      before do
        create(:setting, key: 'customer_service_email', value: 'help@acme.test')
        create(:setting, key: 'mailing_address', value: create(:address).id.to_s)
        create(:setting, key: 'name', value: 'Acme Freight')
        create(:setting, key: 'phone', value: '+15035550100')
      end

      it { is_expected.to(eq(company_name: 'Acme Freight', email: 'help@acme.test', name: 'Acme Freight', phone: '+15035550100')) }
    end

    context 'when object is a staff User' do
      subject(:result) { described_class.new(user).build }

      let(:user) { create(:broker_user) }

      before do
        create(:setting, key: 'customer_service_email', value: 'help@acme.test')
        create(:setting, key: 'name', value: 'Acme Freight')
        create(:setting, key: 'phone', value: '+15035550100')
      end

      it { is_expected.to(include(company_name: 'Acme Freight', email: user.contact.email, phone: '+15035550100')) }
    end

    context 'when object is a staff Contact' do
      subject(:result) { described_class.new(create(:contact, companyable: nil)).build }

      before { create(:setting, key: 'name', value: 'Acme Freight') }

      it { is_expected.to(include(company_name: 'Acme Freight')) }
    end

    context 'when object is a customer User' do
      it { expect { described_class.new(build(:customer_user)) }.to(raise_error(ArgumentError, 'user must be a broker')) }
    end
  end
end
