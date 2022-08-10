# frozen_string_literal: true

class ChangeCreatedByNullOnPayments < ActiveRecord::Migration[7.0]
  def change
    change_column_null :payments, :created_by_id, true
  end
end
