require 'rails_helper'

RSpec.describe(Bank) do
  it_behaves_like 'accounting_syncable', resource: :account, record: 'Accounting::QuickBooks::Account'

  describe 'relationships' do
    it { is_expected.to(have_many(:payments).dependent(:restrict_with_error)) }
  end
end
