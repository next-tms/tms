# frozen_stirng_literal: true

class AddQuickbooksAccountIdToBanks < ActiveRecord::Migration[7.0]
  def change
    add_column :banks, :quickbooks_account_id, :integer, index: true
  end
end
