require 'rails_helper'

RSpec.describe Accounting::QuickBooks::Account do
  let!(:account) { create(:integration) }
  let(:service) { Quickbooks::Service::Account.new }

  before { allow(Quickbooks::Service::Account).to receive(:new).and_return(service) }

  describe '#save' do
    subject(:saved) { record.save }

    let(:record) { described_class.new(account_number: '12345', name: 'Chase: "Main"', sub_type: :credit_card) }

    before { allow(service).to receive(:create) { |model| model.tap { it.id = '3' } } }

    it 'serializes the sub type, sanitizes the name, and marks it a liability bank account' do
      saved

      expect(service).to(have_received(:create) do |model|
        expect(model.account_type).to eq('Bank')
        expect(model.account_sub_type).to eq('CreditCard')
        expect(model.classification).to eq(Quickbooks::Model::Account::LIABILITY)
        expect(model.name).to eq('Chase - Main')
      end)
    end

    context 'when the account number exceeds 20 characters' do
      let(:record) { described_class.new(account_number: '0' * 25, name: 'Bank', sub_type: :checking) }

      it { saved && (expect(service).to(have_received(:create) { |model| expect(model.acct_num).to eq("#{'0' * 17}...") })) }
    end
  end

  describe '.all' do
    subject(:all) { described_class.all.to_a }

    let(:checking) { Quickbooks::Model::Account.new(account_sub_type: 'Checking', classification: 'Liability').tap { it.id = '1' } }
    let(:asset) { Quickbooks::Model::Account.new(account_sub_type: 'Bank', classification: 'Asset').tap { it.id = '2' } }

    before { allow(service).to receive(:all).and_return([ checking, asset ]) }

    it 'returns only Checking/CreditCard liability accounts' do
      expect(all.map(&:id)).to eq([ '1' ])
    end
  end

  describe '.find_by' do
    subject(:found) { described_class.find_by(name: 'Operating') }

    before { allow(service).to receive(:find_by).and_return([ Quickbooks::Model::Account.new(name: 'Operating').tap { it.id = '5' } ]) }

    it 'queries the QuickBooks name field' do
      found

      expect(service).to have_received(:find_by).with(:name, 'Operating')
    end
  end
end
