# frozen_string_literal: true

class AddKindToBanks < ActiveRecord::Migration[7.0]
  def up
    add_column :banks, :kind, :string, index: true

    say 'populate(:banks, :kind)'
    Bank.where(type_id: BankType.where('name ILIKE ?', '%checking%').ids).update_all(kind: :checking)
    Bank.where(type_id: BankType.where('name ILIKE ?', '%credit card%').ids).update_all(kind: :credit_card)

    change_column_null :banks, :kind, false
  end

  def down
    say 'populate(:banks, :type_id)'
    checking_bank_type_id = BankType.find_by_name('Business Checking').id
    credit_card_bank_type_id = BankType.find_by_name('Business Credit Card').id

    Bank.where(kind: :checking).update_all(type_id: checking_bank_type_id)
    Bank.where(kind: :credit_card).update_all(type_id: credit_card_bank_type_id)

    remove_column :banks, :kind
    change_column_null :banks, :type_id, false
  end
end
