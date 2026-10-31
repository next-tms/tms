# == Schema Information
#
# Table name: banks
#
# @!attribute id
#   @return []
# @!attribute account_number
#   @return [String]
# @!attribute kind
#   @return [String]
# @!attribute name
#   @return [String]
# @!attribute accounting_account_id
#   @return [Integer]
#
require 'rails_helper'

RSpec.describe(Bank) do
  it_behaves_like 'accounting_syncable', resource: :account, record: 'Accounting::QuickBooks::Account'
end
