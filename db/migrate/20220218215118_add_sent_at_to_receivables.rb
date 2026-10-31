class AddSentAtToReceivables < ActiveRecord::Migration[7.0]
  def up
    add_column :receivables, :sent_at, :datetime
    add_index :receivables, :sent_at

    say 'populate(:receivables, :sent_at)'
    Receivable.update_all(sent_at: Time.zone.at(0))
  end

  def down
    remove_column :receivables, :sent_at
  end
end
