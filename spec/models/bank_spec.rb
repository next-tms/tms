require 'rails_helper'

RSpec.describe(Bank) do
  it_behaves_like 'accounting_syncable', resource: :account, record: 'Accounting::QuickBooks::Account'
end
