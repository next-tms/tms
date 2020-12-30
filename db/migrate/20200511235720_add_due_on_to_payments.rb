class AddDueOnToPayments < ActiveRecord::Migration[6.0]
  def change
    add_column :payments, :due_on, :date
  end
end
