class CreateBanks < ActiveRecord::Migration[6.0]
  def change
    create_table :banks do |t|
      t.references :broker, null: false, foreign_key: true
      t.references :type, null: false, foreign_key: { to_table: :bank_types }
      t.string :account_number
      t.string :name
    end
  end
end
