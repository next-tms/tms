class AddSentAtToReceivables < ActiveRecord::Migration[7.0]
  def up
    add_column :receivables, :sent_at, :datetime
add_index :receivables, :sent_at

    say 'populate(:receivables, :sent_at)'
    Receivable.all.update_all(sent_at: Time.at(0))
  end

  def down
    remove_column :receivables, :sent_at
  end
end
