require 'rails_helper'

RSpec.describe(Bank) do
  it_behaves_like 'accounting_syncable', resource: :account, record: 'Accounting::QuickBooks::Account'

  describe 'callbacks' do
    let!(:bank) { create(:bank) }
    let!(:integration) { create(:integration) }

    it { expect { bank.update!(name: 'Other') }.to have_enqueued_job(PushBankToAccountingJob).with(bank) }
    it { expect { bank.update!(accounting_account_id: '123') }.not_to have_enqueued_job(PushBankToAccountingJob) }
  end

  describe 'relationships' do
    it { is_expected.to(have_many(:payments).dependent(:restrict_with_error)) }
  end
end
