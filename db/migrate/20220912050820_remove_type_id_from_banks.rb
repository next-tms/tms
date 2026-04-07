class RemoveTypeIdFromBanks < ActiveRecord::Migration[7.0]
  def up
    remove_column :banks, :type_id, :bigint, null: false
  end

  def down
    t.references :type, null: true, foreign_key: { to_table: :bank_types }
  end
end
