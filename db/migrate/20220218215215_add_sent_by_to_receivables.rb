class AddSentByToReceivables < ActiveRecord::Migration[7.0]
  def change
    add_reference :receivables, :sent_by, null: true, foreign_key: { to_table: :users }
  end
end
