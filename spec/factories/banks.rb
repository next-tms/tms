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
FactoryBot.define do
  factory :bank do
    account_number { Faker::Bank.account_number }
    kind { :checking }
    name { Faker::Bank.name }
  end
end
