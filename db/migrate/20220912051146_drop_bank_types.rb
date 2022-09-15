class DropBankTypes < ActiveRecord::Migration[7.0]
  def change
    drop_table :bank_types do |t|
      t.string :name
      t.timestamps
    end
  end
end
